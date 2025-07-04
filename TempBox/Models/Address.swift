//
//  Address.swift
//  TempBox
//
//  Created by Rishi Singh on 01/05/25.
//

import SwiftData
import Foundation

enum AddressSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [Address.self]
    }
    
    @Model
    class Address: Identifiable, Codable {
        var id: String = ""
        var name: String? = nil
        var address: String = ""
        var quota: Int = 0
        var used: Int = 0
        var isDisabled: Bool = true // disabled set to true by default
        var isDeleted: Bool = false
        var createdAt: Date = Date.now
        var updatedAt: Date = Date.now
        var token: String?
        var password: String = ""
            
        init(
            id: String,
            name: String?,
            address: String,
            quota: Int,
            used: Int,
            isDisabled: Bool = false,
            isDeleted: Bool = false,
            createdAt: Date,
            updatedAt: Date,
            token: String,
            password: String,
        ) {
            self.id = id
            self.name = name
            self.address = address
            self.quota = quota
            self.used = used
            self.isDisabled = isDisabled
            self.isDeleted = isDeleted
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.token = token
            self.password = password
        }
        
        // Codable implementation
        enum CodingKeys: String, CodingKey {
            case id, name, address, quota, used, isDisabled, isDeleted, createdAt, updatedAt, token, password, isActive
        }
        
        var ifNameElseAddress: String {
            if let name = name, !name.isEmpty {
                return name
            } else {
                return address
            }
        }
        
        var ifNameThenAddress: String {
            if let name = name, !name.isEmpty {
                return address
            } else {
                return ""
            }
        }
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            id = try container.decode(String.self, forKey: .id)
            
            name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
            address = try container.decode(String.self, forKey: .address)
            quota = try container.decode(Int.self, forKey: .quota)
            used = try container.decode(Int.self, forKey: .used)
            isDisabled = try container.decode(Bool.self, forKey: .isDisabled)
            isDeleted = try container.decode(Bool.self, forKey: .isDeleted)
            
            // Handle Date - parse from string if needed
            if let createdAtString = try? container.decode(String.self, forKey: .createdAt),
               let date = createdAtString.toDate() {
                createdAt = date
            } else {
                createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date.now
            }
            
            if let updatedAtString = try? container.decode(String.self, forKey: .updatedAt),
               let date = updatedAtString.toDate() {
                updatedAt = date
            } else {
                updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date.now
            }
            
            token = try container.decodeIfPresent(String.self, forKey: .token)
            password = try container.decode(String.self, forKey: .password)
        }
            
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(id, forKey: .id)
            try container.encode(name, forKey: .name)
            try container.encode(address, forKey: .address)
            try container.encode(quota, forKey: .quota)
            try container.encode(used, forKey: .used)
            try container.encode(isDisabled, forKey: .isDisabled)
            try container.encode(isDeleted, forKey: .isDeleted)
            
            // Format dates as ISO8601 strings
            let dateFormatter = ISO8601DateFormatter()
            try container.encode(dateFormatter.string(from: createdAt), forKey: .createdAt)
            try container.encode(dateFormatter.string(from: updatedAt), forKey: .updatedAt)
            
            try container.encodeIfPresent(token, forKey: .token)
            try container.encode(password, forKey: .password)
        }
    }
}

enum AddressSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [Address.self]
    }
    
    @Model
    class Address: Identifiable, Codable {
        var id: String = ""
        var name: String? = nil
        /// The email address associated with this address
        var address: String = ""
        var quota: Int = 0
        var used: Int = 0
        var isArchived: Bool = false
        var isDeleted: Bool = false
        var createdAt: Date = Date.now
        var updatedAt: Date = Date.now
        var token: String?
        var password: String = ""
            
        init(
            id: String,
            name: String?,
            address: String,
            quota: Int,
            used: Int,
            isArchived: Bool = false,
            isDeleted: Bool = false,
            createdAt: Date,
            updatedAt: Date,
            token: String,
            password: String,
        ) {
            self.id = id
            self.name = name
            self.address = address
            self.quota = quota
            self.used = used
            self.isArchived = isArchived
            self.isDeleted = isDeleted
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.token = token
            self.password = password
        }
        
        // Codable implementation
        enum CodingKeys: String, CodingKey {
            case id, name, address, quota, used, isArchived, isDeleted, createdAt, updatedAt, token, password, isActive
        }
        
        var ifNameElseAddress: String {
            if let name = name, !name.isEmpty {
                return name
            } else {
                return address
            }
        }
        
        var ifNameThenAddress: String {
            if let name = name, !name.isEmpty {
                return address
            } else {
                return ""
            }
        }
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            id = try container.decode(String.self, forKey: .id)
            
            name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
            address = try container.decode(String.self, forKey: .address)
            quota = try container.decode(Int.self, forKey: .quota)
            used = try container.decode(Int.self, forKey: .used)
            isArchived = try container.decode(Bool.self, forKey: .isArchived)
            isDeleted = try container.decode(Bool.self, forKey: .isDeleted)
            
            // Handle Date - parse from string if needed
            if let createdAtString = try? container.decode(String.self, forKey: .createdAt),
               let date = createdAtString.toDate() {
                createdAt = date
            } else {
                createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date.now
            }
            
            if let updatedAtString = try? container.decode(String.self, forKey: .updatedAt),
               let date = updatedAtString.toDate() {
                updatedAt = date
            } else {
                updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date.now
            }
            
            token = try container.decodeIfPresent(String.self, forKey: .token)
            password = try container.decode(String.self, forKey: .password)
        }
            
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(id, forKey: .id)
            try container.encode(name, forKey: .name)
            try container.encode(address, forKey: .address)
            try container.encode(quota, forKey: .quota)
            try container.encode(used, forKey: .used)
            try container.encode(isArchived, forKey: .isArchived)
            try container.encode(isDeleted, forKey: .isDeleted)
            
            // Format dates as ISO8601 strings
            let dateFormatter = ISO8601DateFormatter()
            try container.encode(dateFormatter.string(from: createdAt), forKey: .createdAt)
            try container.encode(dateFormatter.string(from: updatedAt), forKey: .updatedAt)
            
            try container.encodeIfPresent(token, forKey: .token)
            try container.encode(password, forKey: .password)
        }
    }
}


typealias Address = AddressSchemaV2.Address
