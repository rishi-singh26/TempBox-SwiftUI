//
//  CompleteMessage.swift
//  TempMail
//
//  Created by Rishi Singh on 01/05/25.
//

import Foundation

struct CompleteMessage: Codable, Identifiable {
    // Use the server's ID as our Identifiable ID
    var id: String {
        return messageId ?? ""
    }
    
    let messageId: String?
    let from: Address?
    let to: [Address]?
    let cc: [Address]?
    let bcc: [Address]?
    let subject: String
    let intro: String
    let seen: Bool
    let isDeleted: Bool
    let hasAttachments: Bool
    let size: Int
    let retention: Bool?
    let retentionDate: String?
    let text: String?
    let html: [String]?
    let attachments: [Attachment]?
    let downloadUrl: String?
    let sourceUrl: String?
    let createdAt: String
    let updatedAt: String?
    let accountId: String?
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        messageId = try container.decodeIfPresent(String.self, forKey: .messageId)
        from = try container.decodeIfPresent(Address.self, forKey: .from)
        to = try container.decodeIfPresent([Address].self, forKey: .to)
        cc = try container.decodeIfPresent([Address].self, forKey: .cc)
        bcc = try container.decodeIfPresent([Address].self, forKey: .bcc)
        subject = try container.decode(String.self, forKey: .subject)
        intro = try container.decode(String.self, forKey: .intro)
        seen = try container.decode(Bool.self, forKey: .seen)
        isDeleted = try container.decode(Bool.self, forKey: .isDeleted)
        hasAttachments = try container.decode(Bool.self, forKey: .hasAttachments)
        size = try container.decode(Int.self, forKey: .size)
        retention = try container.decodeIfPresent(Bool.self, forKey: .retention)
        retentionDate = try container.decodeIfPresent(String.self, forKey: .retentionDate)
        text = try container.decodeIfPresent(String.self, forKey: .text)
        html = try container.decodeIfPresent([String].self, forKey: .html)
        attachments = try container.decodeIfPresent([Attachment].self, forKey: .attachments)
        downloadUrl = try container.decodeIfPresent(String.self, forKey: .downloadUrl)
        sourceUrl = try container.decodeIfPresent(String.self, forKey: .sourceUrl)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        accountId = try container.decodeIfPresent(String.self, forKey: .accountId)
    }

    enum CodingKeys: String, CodingKey {
        case messageId = "msgid"
        case from, to, cc, bcc, subject, intro, seen, isDeleted, hasAttachments, size
        case retention, retentionDate, text, html, attachments
        case downloadUrl, sourceUrl, createdAt, updatedAt, accountId
    }

    var fromAddress: String {
        if let safeFrom = from {
            return "\(safeFrom.name) <\(safeFrom.address)>"
        } else {
            return ""
        }
    }
    
    var toAddress: String {
        if let safeTo = to {
            if safeTo.isEmpty {
                return "No recipients"
            }
            return safeTo.map { "\($0.name) <\($0.address)>" }.joined(separator: ", ")
        } else {
            return ""
        }
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

struct Address: Codable {
    let address: String
    let name: String

    // Some APIs might return just the address without a name field
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        address = try container.decode(String.self, forKey: .address)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
    }
    
    enum CodingKeys: String, CodingKey {
        case address, name
    }
}

struct Attachment: Codable, Identifiable {
    let id: String
    let filename: String?
    let contentType: String?
    let disposition: String?
    let transferEncoding: String?
    let related: Bool?
    let size: Int?
    let downloadUrl: String?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        filename = try container.decodeIfPresent(String.self, forKey: .filename)
        contentType = try container.decodeIfPresent(String.self, forKey: .contentType)
        disposition = try container.decodeIfPresent(String.self, forKey: .disposition)
        transferEncoding = try container.decodeIfPresent(String.self, forKey: .transferEncoding)
        related = try container.decodeIfPresent(Bool.self, forKey: .related)
        size = try container.decodeIfPresent(Int.self, forKey: .size)
        downloadUrl = try container.decodeIfPresent(String.self, forKey: .downloadUrl)
    }

    enum CodingKeys: String, CodingKey {
        case id, filename, contentType, disposition, transferEncoding, related, size, downloadUrl
    }
}

struct APIError: Codable, Error {
    let title: String?
    let detail: String?
    let status: Int?
    let type: String?
    
    var localizedDescription: String {
        return detail ?? title ?? "Unknown error occurred"
    }
}

struct APIResponse: Codable {
    let status: String?
    let message: String?
}
