//
//  Message.swift
//  TempBox (macOS)
//
//  Created by Rishi Singh on 26/09/23.
//

import Foundation

struct Message: Codable, Identifiable {
    let id: String
    let accountId: String
    let msgid: String
    let from: EmailAddress
    let to: [EmailAddress]
    let cc: [EmailAddress]?
    let bcc: [EmailAddress]?
    let subject: String
    let intro: String?
    let text: String?
    let html: [String]?
    let seen: Bool
    let flagged: Bool?
    let isDeleted: Bool
    let verifications: MessageVerifications?
    let retention: Bool?
    let retentionDate: String?
    let hasAttachments: Bool
    let attachments: [Attachment]?
    let size: Int
    let downloadUrl: String
    let sourceUrl: String
    let createdAt: String
    let updatedAt: String
}

extension Message: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Message: Equatable {
    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id
    }
}

extension Message {
    var createdAtFormatted: String { createdAt.validateAndToDate()?.formatRelativeString() ?? "" }

    var updatedAtDate: String { updatedAt.validateAndToDate()?.formatRelativeString() ?? "" }

    var fromAddress: String { "\(from.name != nil ? "\(from.name!) " : "")<\(from.address)>" }

    var fromName: String { from.name ?? "" }

    var toAddress: String {
        to.map {
            if let name = $0.name, !name.isEmpty {
                return "\(name) <\($0.address)>"
            } else {
                return "<\($0.address)>"
            }
        }.joined(separator: ", ")
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

extension Message {
    func copyWith(seen: Bool) -> Message {
        Message(
            id: self.id,
            accountId: self.accountId,
            msgid: self.msgid,
            from: self.from,
            to: self.to,
            cc: self.cc,
            bcc: self.bcc,
            subject: self.subject,
            intro: self.intro,
            text: self.text,
            html: self.html,
            seen: seen,
            flagged: self.flagged,
            isDeleted: self.isDeleted,
            verifications: self.verifications,
            retention: self.retention,
            retentionDate: self.retentionDate,
            hasAttachments: self.hasAttachments,
            attachments: self.attachments,
            size: self.size,
            downloadUrl: self.downloadUrl,
            sourceUrl: self.sourceUrl,
            createdAt: self.createdAt,
            updatedAt: self.updatedAt
        )
    }
}

struct Attachment: Codable, Identifiable {
    let id: String
    let filename: String
    let contentType: String
    let disposition: String
    let transferEncoding: String
    let related: Bool
    let size: Int
    let downloadUrl: String
}

struct EmailAddress: Codable {
    let name: String?
    let address: String
}

struct MessageVerifications: Codable {
    struct TLS: Codable {
        let name: String
        let standardName: String
        let version: String
    }
    
    let tls: TLS
    let spf: Bool
    let dkim: Bool
}


struct MarkAsReadResponse: Codable {
    let seen: Bool
}
