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
    
    var safeAttachments: [Attachment] {
        hasAttachments ? attachments ?? [] : []
    }

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

struct Attachment: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let filename: String
    let contentType: String
    let disposition: String
    let transferEncoding: String
    let related: Bool
    let size: Int
    let downloadUrl: String
    
    var iconForAttachment: String {
        let contentType = contentType.lowercased()
        let filename = filename.lowercased()
        
        if contentType.hasPrefix("image/") {
            return "photo"
        } else if contentType == "application/pdf" || filename.hasSuffix(".pdf") {
            return "doc.richtext"
        } else if contentType.hasPrefix("text/") || filename.hasSuffix(".txt") {
            return "doc.text"
        } else if contentType.contains("zip") || contentType.contains("archive") {
            return "archivebox"
        } else if contentType.contains("video/") {
            return "video"
        } else if contentType.contains("audio/") {
            return "music.note"
        } else {
            return "doc"
        }
    }
    
    var sizeString: String {
        var unit = SizeUnit.KB
        if size > 1024 {
            unit = SizeUnit.MB
        }
        return String(ByteConverterService(kiloBytes: Double(size)).toHumanReadable(unit: unit))
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Attachment, rhs: Attachment) -> Bool {
        lhs.id == rhs.id
    }
}

struct AttachmentDownload {
    let fileURL: URL
    let fileData: Data
    let filename: String
    let contentType: String
    let messageId: String
    let attachmentId: String
}

extension AttachmentDownload {
    var fileExtension: String {
        return (filename as NSString).pathExtension.lowercased()
    }
    
    var isImage: Bool {
        return contentType.hasPrefix("image/") || ["jpg", "jpeg", "png", "gif", "bmp", "webp"].contains(fileExtension)
    }
    
    var isPDF: Bool {
        return contentType == "application/pdf" || fileExtension == "pdf"
    }
    
    var isText: Bool {
        return contentType.hasPrefix("text/") || ["txt", "md", "json", "xml", "html", "css", "js"].contains(fileExtension)
    }
    
    var isPreviewable: Bool {
        return isImage || isPDF || isText
    }
    
    func cleanupTemporaryFile() {
        try? FileManager.default.removeItem(at: fileURL)
    }
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
