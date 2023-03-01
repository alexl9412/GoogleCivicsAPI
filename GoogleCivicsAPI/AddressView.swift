//
//  AddressView.swift
//  GoogleCivicsAPI
//
//  Created by Alex Lenkei on 3/1/23.
//

import SwiftUI
import Combine
import CoreLocation
import MapKit

struct AddressView: View {
	@StateObject private var mapSearch = MapSearch()
	
	@FocusState private var isFocused: Bool
	@State private var address = ""
	
	@StateObject var viewModel = ElectionViewModel()
	@State private var hasError = false
	@State private var error: ElectionViewModel.VoterInfoError?

	var body: some View {
		NavigationStack {
			VStack {
				List {
					Section {
						TextField("Enter your address", text: $mapSearch.searchTerm, axis: .vertical)
						
						if address != mapSearch.searchTerm && isFocused == false {
							ForEach(mapSearch.locationResults, id: \.self) { location in
								Button {
									reverseGeo(location: location)
									Task {
										do {
											try await viewModel.fetchVoterInfo(for: location.title + ", " + location.subtitle)
										} catch {
											if let userError = error as? ElectionViewModel.VoterInfoError {
												self.hasError = true
												self.error = userError
											}
										}
									}
								} label: {
									VStack(alignment: .leading, spacing: 3) {
										Text(location.title)
											.foregroundColor(.primary)
										Text(location.subtitle)
											.font(.system(.caption))
											.foregroundColor(.primary)
									}
								}
							}
						}
					}
					.listSectionSeparator(.hidden)
					if viewModel.isRefreshing {
						ProgressView()
					} else {
						Section {
							ForEach(viewModel.pollingLocations, id: \.address) { location in
								VStack(alignment: .leading, spacing: 5) {
									Text(location.address.locationName)
									Text(location.address.line1)
									Text(location.address.city + ", " + location.address.state)
									Text(location.address.zip)
									Text("Hours: " + location.pollingHours)
								}
							}
						}
					}
				}
			}
			.navigationTitle("Polling location")
			.alert(isPresented: $hasError, error: error) {
				Button("OK", role: .cancel) { }
			}
		}
	}
	
	func reverseGeo(location: MKLocalSearchCompletion) {
		let searchRequest = MKLocalSearch.Request(completion: location)
		let search = MKLocalSearch(request: searchRequest)
		var coordinateK : CLLocationCoordinate2D?
		search.start { (response, error) in
			if error == nil, let coordinate = response?.mapItems.first?.placemark.coordinate {
				coordinateK = coordinate
			}
			
			if let c = coordinateK {
				let location = CLLocation(latitude: c.latitude, longitude: c.longitude)
				CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
					
					guard let placemark = placemarks?.first else {
						let errorString = error?.localizedDescription ?? "Unexpected Error"
						print("Unable to reverse geocode the given location. Error: \(errorString)")
						return
					}
					
					let reversedGeoLocation = ReversedGeoLocation(with: placemark)
					
					address = "\(reversedGeoLocation.formattedAddress)"
					mapSearch.searchTerm = address
					isFocused = false
				}
			}
		}
	}
}

struct AddressView_Previews: PreviewProvider {
	static var previews: some View {
		AddressView()
	}
}
