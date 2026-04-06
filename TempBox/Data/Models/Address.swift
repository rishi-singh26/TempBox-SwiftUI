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

enum AddressSchemaV3: VersionedSchema {
    static var versionIdentifier = Schema.Version(3, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [Address.self, Folder.self]
    }
    
    @Model
    class Folder: Identifiable, Codable {
        var id: String = ""
        var name: String = ""
        var color: String? = nil
        var isArchived: Bool = false
        var isDeleted: Bool = false
        var createdAt: Date = Date.now
        var updatedAt: Date = Date.now
        
        // One-to-many relationship with Address
        @Relationship(deleteRule: .nullify, inverse: \Address.folder)
        var addresses: [Address]? = []
        
        init(
            id: String,
            name: String,
            color: String? = nil,
            isArchived: Bool = false,
            isDeleted: Bool = false,
            createdAt: Date = Date.now,
            updatedAt: Date = Date.now
        ) {
            self.id = id
            self.name = name
            self.color = color
            self.isArchived = isArchived
            self.isDeleted = isDeleted
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
        
        // Codable implementation
        enum CodingKeys: String, CodingKey {
            case id, name, color, isArchived, isDeleted, createdAt, updatedAt
        }
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            id = try container.decode(String.self, forKey: .id)
            name = try container.decode(String.self, forKey: .name)
            color = try container.decodeIfPresent(String.self, forKey: .color)
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
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(id, forKey: .id)
            try container.encode(name, forKey: .name)
            try container.encodeIfPresent(color, forKey: .color)
            try container.encode(isArchived, forKey: .isArchived)
            try container.encode(isDeleted, forKey: .isDeleted)
            
            // Format dates as ISO8601 strings
            let dateFormatter = ISO8601DateFormatter()
            try container.encode(dateFormatter.string(from: createdAt), forKey: .createdAt)
            try container.encode(dateFormatter.string(from: updatedAt), forKey: .updatedAt)
        }
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
        
        // Many-to-one relationship with Folder (optional - address can exist without a folder)
        @Relationship
        var folder: Folder?
        
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
            folder: Folder? = nil
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
            self.folder = folder
        }
        
        // Codable implementation
        enum CodingKeys: String, CodingKey {
            case id, name, address, quota, used, isArchived, isDeleted, createdAt, updatedAt, token, password, folderId
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
            
            // Note: folder relationship will be handled separately during data loading
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
            
            // Encode folder ID for JSON serialization
            try container.encodeIfPresent(folder?.id, forKey: .folderId)
        }
    }
}

enum AddressSchemaV4: VersionedSchema {
    static var versionIdentifier = Schema.Version(4, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [Address.self, Folder.self]
    }
    
    @Model
    class Folder: Identifiable, Codable {
        var id: String = ""
        var name: String = ""
        var color: String? = nil
        var isArchived: Bool = false
        var isDeleted: Bool = false
        var createdAt: Date = Date.now
        var updatedAt: Date = Date.now
        
        // One-to-many relationship with Address
        @Relationship(deleteRule: .nullify, inverse: \Address.folder)
        var addresses: [Address]? = []
        
        init(
            id: String,
            name: String,
            color: String? = nil,
            isArchived: Bool = false,
            isDeleted: Bool = false,
            createdAt: Date = Date.now,
            updatedAt: Date = Date.now
        ) {
            self.id = id
            self.name = name
            self.color = color
            self.isArchived = isArchived
            self.isDeleted = isDeleted
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
        
        // Codable implementation
        enum CodingKeys: String, CodingKey {
            case id, name, color, isArchived, isDeleted, createdAt, updatedAt
        }
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            id = try container.decode(String.self, forKey: .id)
            name = try container.decode(String.self, forKey: .name)
            color = try container.decodeIfPresent(String.self, forKey: .color)
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
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(id, forKey: .id)
            try container.encode(name, forKey: .name)
            try container.encodeIfPresent(color, forKey: .color)
            try container.encode(isArchived, forKey: .isArchived)
            try container.encode(isDeleted, forKey: .isDeleted)
            
            // Format dates as ISO8601 strings
            let dateFormatter = ISO8601DateFormatter()
            try container.encode(dateFormatter.string(from: createdAt), forKey: .createdAt)
            try container.encode(dateFormatter.string(from: updatedAt), forKey: .updatedAt)
        }
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
        
        // Many-to-one relationship with Folder (optional - address can exist without a folder)
        @Relationship
        var folder: Folder?
        
        @Relationship(deleteRule: .cascade, inverse: \Message.address)
        var messages: [Message]?
        
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
            folder: Folder? = nil
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
            self.folder = folder
        }
        
        // Codable implementation
        enum CodingKeys: String, CodingKey {
            case id, name, address, quota, used, isArchived, isDeleted, createdAt, updatedAt, token, password, folderId
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
            
            // Note: folder relationship will be handled separately during data loading
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
            
            // Encode folder ID for JSON serialization
            try container.encodeIfPresent(folder?.id, forKey: .folderId)
        }
    }
    
    @Model
    class Message: Identifiable {
        var id: UUID = UUID()

        var remoteId: String = ""
        var accountId: String = ""
        var msgid: String = ""
        
        var fromName: String?
        var fromAddress: String = ""
        var to: String = ""
        
        var cc: String?
        var bcc: String?
        
        var subject: String = ""
        var intro: String?
        var text: String?
        var html: [String]? = nil
        
        var seen: Bool = false
        var flagged: Bool?
        var isDeleted: Bool = false
        
        var retention: Bool?
        var retentionDate: String?
        
        var hasAttachments: Bool = false
        var attachments: [Attachment]? = nil
        
        var size: Int = 0
        
        var downloadUrl: String = ""
        var sourceUrl: String = ""
        
        var createdAt: String = "" // "2026-04-05T15:50:36+00:00"
        var updatedAt: String = "" // "2026-04-06T09:29:07+00:00"
        
        @Relationship
        var address: Address?
        
        init(
            id: UUID = UUID(),
            remoteId: String,
            accountId: String,
            msgid: String,
            fromName: String?,
            fromAddress: String,
            to: String,
            cc: String? = nil,
            bcc: String? = nil,
            subject: String,
            intro: String? = nil,
            text: String? = nil,
            html: [String]? = nil,
            seen: Bool,
            flagged: Bool? = nil,
            isDeleted: Bool,
            retention: Bool? = nil,
            retentionDate: String? = nil,
            hasAttachments: Bool,
            attachments: [Attachment]? = nil,
            size: Int,
            downloadUrl: String,
            sourceUrl: String,
            createdAt: String,
            updatedAt: String,
            address: Address? = nil
        ) {
            self.id = id
            self.remoteId = remoteId
            self.accountId = accountId
            self.msgid = msgid
            self.fromName = fromName
            self.fromAddress = fromAddress
            self.to = to
            self.cc = cc
            self.bcc = bcc
            self.subject = subject
            self.intro = intro
            self.text = text
            self.html = html
            self.seen = seen
            self.flagged = flagged
            self.isDeleted = isDeleted
            self.retention = retention
            self.retentionDate = retentionDate
            self.hasAttachments = hasAttachments
            self.attachments = attachments
            self.size = size
            self.downloadUrl = downloadUrl
            self.sourceUrl = sourceUrl
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.address = address
        }
    }
}

typealias Address = AddressSchemaV4.Address
typealias Folder = AddressSchemaV4.Folder
typealias Message = AddressSchemaV4.Message

extension Message {
    static func flatten(emailAddresses: [EmailAddress]?) -> String? {
        guard let emailAddresses, !emailAddresses.isEmpty else { return nil }
        
        return emailAddresses
            .map { address in
                let name = address.name ?? ""
                return "\(name)::\(address.address)"
            }
            .joined(separator: ":::")
    }
}

extension Message {
    convenience init(api: APIMessage) {
        self.init(
            id: UUID(), // or UUID(uuidString: api.id) if backend supports it
            remoteId: api.id,
            accountId: api.accountId,
            msgid: api.msgid,
            fromName: api.from.name,
            fromAddress: api.from.address,
            to: Self.flatten(emailAddresses: api.to) ?? "",
            cc: Self.flatten(emailAddresses: api.cc),
            bcc: Self.flatten(emailAddresses: api.bcc),
            subject: api.subject,
            intro: api.intro,
            text: api.text,
            html: api.html,
            seen: api.seen,
            flagged: api.flagged,
            isDeleted: api.isDeleted,
            retention: api.retention,
            retentionDate: api.retentionDate,
            hasAttachments: api.hasAttachments,
            attachments: api.attachments,
            size: api.size,
            downloadUrl: api.downloadUrl,
            sourceUrl: api.sourceUrl,
            createdAt: api.createdAt,
            updatedAt: api.updatedAt,
            address: nil // handle separately if needed
        )
    }
    
    func update(with apiMessage: APIMessage) {
        intro = apiMessage.intro
        text = apiMessage.text
        html = apiMessage.html
        seen = apiMessage.seen
        flagged = apiMessage.flagged
        isDeleted = apiMessage.isDeleted
        retention = apiMessage.retention
        retentionDate = apiMessage.retentionDate
        hasAttachments = apiMessage.hasAttachments
        attachments = apiMessage.attachments
        size = apiMessage.size
        downloadUrl = apiMessage.downloadUrl
        sourceUrl = apiMessage.sourceUrl
        createdAt = apiMessage.createdAt
        updatedAt = apiMessage.updatedAt
    }
}

extension Message {
    var createdAtFormatted: String { createdAt.validateAndToDate()?.formatRelativeString() ?? "" }

    var updatedAtDate: String { updatedAt.validateAndToDate()?.formatRelativeString() ?? "" }
    
    /// Swift Date object from the string date in API response
    var created: Date? {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: createdAt) {
            return date
        } else {
            return nil
        }
    }
    
    /// Swift Date object from the string date in API response
    var updated: Date? {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: updatedAt) {
            return date
        } else {
            return nil
        }
    }
    
    var safeAttachments: [Attachment] {
        hasAttachments ? attachments ?? [] : []
    }

    var formattedDate: String {
        // Format the date string
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        guard let date = dateFormatter.date(from: createdAt) else {
            return createdAt
        }
        
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: date)
    }
}

extension Address {
    static func empty(id: String) -> Address {
        Address(id: id, name: "", address: "", quota: 0, used: 0, createdAt: Date.now, updatedAt: Date.now, token: "", password: "")
    }
}
