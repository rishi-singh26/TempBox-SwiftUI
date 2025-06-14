//
//  ImportExport.swift
//  TempBox
//
//  Created by Rishi Singh on 02/05/25.
//

import Foundation

enum ExportError: Error {
    case objectToDataConversionFailed
    case encodingFailed(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .objectToDataConversionFailed:
            return "Failed to convert export object to data."
        case .encodingFailed(let underlying):
            return "Failed to encode object to JSON. Reason: \(underlying.localizedDescription)"
        }
    }
}

struct VersionContainer: Codable {
    let version: String
}

// MARK: - Export Version Two models
struct ExportVersionTwo: Codable, JSONEncodable {
    let version: String = "2.0.0"
    static let staticVersion: String = "2.0.0"
    let exportDate: String
    let addresses: [ExportVersionTwoAddress]
    
    init(addresses: [ExportVersionTwoAddress]) {
        self.addresses = addresses
        self.exportDate = Date.now.ISO8601Format()
    }

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
        addresses = try container.decode([ExportVersionTwoAddress].self, forKey: .addresses)
    }

    /// Encodes the object to JSON string
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
    
    /// Encodes the object to JSON data
    func toJSON(prettyPrinted: Bool = true) throws -> Data {
        let encoder = JSONEncoder()
        if prettyPrinted {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        }
        do {
            return try encoder.encode(self)
        } catch {
            throw ExportError.objectToDataConversionFailed
        }
    }
    
    func toCSV() -> String {
        // CSV Header
        var csv = "Address Name,Email,Password,Archived,Created At,ID\n"

        // CSV Rows
        for address in addresses {
            let row = [
                address.addressName ?? "",
                address.email,
                address.password,
                address.archived,
                address.createdAt,
                address.id,
            ]
            .map { "\"\($0.replacingOccurrences(of: "\"", with: "\"\""))\"" } // escape quotes
            .joined(separator: ",")

            csv.append(row + "\n")
        }
        return csv
    }
}

struct ExportVersionTwoAddress: Codable, Hashable, Identifiable {
    let addressName: String?
    let id: String
    let email: String
    let password: String
    let archived: String
    let createdAt: String
    
    var createdAtDate: Date {
        createdAt.validateAndToDate() ?? Date.now
    }
    
    var ifNameElseAddress: String {
        if let name = addressName, !name.isEmpty {
            return name
        } else {
            return email
        }
    }
        
    var ifNameThenAddress: String {
        if let name = addressName, !name.isEmpty {
            return email
        } else {
            return ""
        }
    }
}

// MARK: - Export Version One models
struct ExportVersionOne: Codable {
    static let staticVersion: String = "1.0.0"
    let version: String = "1.0.0"
    let exportDate: String
    let addresses: [ExportVersionOneAddress]
    
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
        addresses = try container.decode([ExportVersionOneAddress].self, forKey: .addresses)
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

struct ExportVersionOneAddress: Codable, Equatable, Identifiable, Hashable {
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

    static func == (lhs: ExportVersionOneAddress, rhs: ExportVersionOneAddress) -> Bool {
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
