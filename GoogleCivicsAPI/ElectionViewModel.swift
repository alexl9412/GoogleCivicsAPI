//
//  ElectionViewModel.swift
//  GoogleCivicsAPI
//
//  Created by Alex Lenkei on 3/1/23.
//

import Foundation

@MainActor
class ElectionViewModel: ObservableObject {
	@Published private(set) var isRefreshing = false
	@Published var pollingLocations = [PollingLocation]()
	
	let key = "api key"
	
	// MARK: voterInfoQuery method: https://developers.google.com/civic-information/docs/v2/elections/voterInfoQuery
	
	func fetchVoterInfo(for address: String) async throws {
		if let url = URL(string: "https://www.googleapis.com/civicinfo/v2/voterinfo?key=\(key)&address=\(address)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "invalid") {
			
			do {
				let (data, response) = try await URLSession.shared.data(from: url)
				
				guard let response = response as? HTTPURLResponse,
					  response.statusCode >= 200 && response.statusCode <= 299 else {
					
					// would like to replace this error with the errors this API can return: https://developers.google.com/civic-information/docs/v2/errors
					throw VoterInfoError.invalidStatusCode
				}
				let decoder = JSONDecoder()
				guard let decodedResponse = try? decoder.decode(VoterInfoResponse.self, from: data) else {
					throw VoterInfoError.failedToDecode
				}
				
				pollingLocations = decodedResponse.pollingLocations
				
			} catch {
				throw VoterInfoError.custom(error: error)
			}
		}
	}
	
	// MARK: enum of possible errors; error names and descriptions from API docs: https://developers.google.com/civic-information/docs/v2/errors
	enum VoterInfoError: LocalizedError {
		case failedToDecode
		case invalidStatusCode
		case parseError
		case required
		case invalidValue
		case invalidQuery
		case unauthorized
		case limitExceeded
		case notFound
		case backendError
		case custom(error: Error)
		
		var errorDescription: String? {
			switch self {
			case .failedToDecode:
				return "Failed to decode response"
			case .invalidStatusCode:
				return "Request falls in an invalid range"
			case .parseError:
				return "The address sent to the API was not parseable. This may happen if the address is not completely specified."
			case .required:
				return "An address must be specified for this request."
			case .invalidValue:
				return "The election that was requested is unknown. This may be because the requested election ID is invalid. This may also happen for requests without an election id specified if there is no data available for the provided address."
			case .invalidQuery:
				return "The requested is election is over. Data is no longer available for this election."
			case .unauthorized:
				return "The request was not appropriately authorized."
			case .limitExceeded:
				return "The recursive request required processing too many divisions. Try applying additional filters and/or using a more constrained OCD ID."
			case .notFound:
				return "The API does not have any information for this address. This may be because the address is not a US residential address. Another reason for this error is if there is no election data for this address."
			case .backendError:
				return "The API is experiencing a problem responding to the request. These types of errors can be retried."
			case .custom(let error):
				return error.localizedDescription
			}
		}
	}
}
