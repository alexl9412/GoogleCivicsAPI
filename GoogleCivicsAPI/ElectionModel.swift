//
//  ElectionModel.swift
//  GoogleCivicsAPI
//
//  Created by Alex Lenkei on 3/1/23.
//

import Foundation

struct VoterInfoResponse: Codable {
	let election: Election
	let pollingLocations: [PollingLocation]
}

struct Election: Codable {
	let id: String
	let name: String
	let electionDay: String
	let ocdDivisionId: String
}

struct PollingLocation: Codable {
	let address: Address
	let notes: String
	let pollingHours: String
}

struct Address: Codable, Hashable {
	let locationName: String
	let line1: String
	let city: String
	let state: String
	let zip: String
}

struct APIError: Codable {
	let code: Int
	let message: String
}
