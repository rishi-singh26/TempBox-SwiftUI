//
//  ImportExport.swift
//  TempMail
//
//  Created by Rishi Singh on 02/05/25.
//

import Foundation

struct VersionContainer: Codable {
    let version: String
}

struct ExportVersionTwo: Codable {
    let version: String = "2.0.0"
    let exportDate: String
    let addresses: [Address]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedVersion = try container.decode(String.self, forKey: .version)
        guard decodedVersion == version else {
            throw DecodingError.dataCorruptedError(
                forKey: .version,
                in: container,
                debugDescription: "Unsupported version: \(decodedVersion). Expected version: \(version)."
            )
        }
        exportDate = try container.decode(String.self, forKey: .exportDate)
        addresses = try container.decode([Address].self, forKey: .addresses)
    }

    /// Encodes the object to JSON data or a JSON string
    func toJSON(prettyPrinted: Bool = true) throws -> String {
        let encoder = JSONEncoder()
        if prettyPrinted {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        }
        let data = try encoder.encode(self)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw EncodingError.invalidValue(self, .init(
                codingPath: [],
                debugDescription: "Failed to convert data to UTF-8 string."
            ))
        }
        return jsonString
    }
}


struct ExportVersionOne: Codable {
    let version: String = "1.0.0"
    let exportDate: String
    let addresses: [AddressData]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedVersion = try container.decode(String.self, forKey: .version)
        guard decodedVersion == version else {
            throw DecodingError.dataCorruptedError(
                forKey: .version,
                in: container,
                debugDescription: "Unsupported version: \(decodedVersion). Expected version: \(version)."
            )
        }
        exportDate = try container.decode(String.self, forKey: .exportDate)
        addresses = try container.decode([AddressData].self, forKey: .addresses)
    }
}

struct AddressData: Codable, Equatable, Identifiable, Hashable {
    var id: String {
        authenticatedUser.account.id
    }
    let addressName: String
    let authenticatedUser: AuthenticatedUser
    let password: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(authenticatedUser.account.id)
        hasher.combine(authenticatedUser.account.address)
    }

    static func == (lhs: AddressData, rhs: AddressData) -> Bool {
        return lhs.authenticatedUser.account.id == rhs.authenticatedUser.account.id
        
    }
}

struct AuthenticatedUser: Codable, Equatable {
    var account: ExportedAccountVOne
    let password: String
    let token: String
}

struct ExportedAccountVOne: Codable, Equatable {
    let id: String
    let address: String
    let quota: Int
    let used: Int
    let isDisabled: Bool
    let isDeleted: Bool
    let createdAt: String
    let updatedAt: String
}
