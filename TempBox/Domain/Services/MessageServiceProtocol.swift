//
//  MessageServiceProtocol.swift
//  TempBox
//
//  Created by Rishi Singh on 06/04/26.
//

import Foundation

@MainActor
protocol MessageServiceProtocol {
    /// Fetches messages for an address from the API and upserts them locally.
    /// Throws if the network request fails.
    func fetchMessages(for address: Address) async throws
    /// Fetches and saves the complete message body for a single message.
    func fetchCompleteMessage(of message: Message) async
    /// Concurrently fetches complete bodies for a set of messages.
    func fetchCompleteMessages(for messages: [Message], address: Address) async
    /// Toggles the seen status of a message (local + server).
    func updateSeenStatus(_ message: Message) async
    /// Deletes a message from the server and removes it from local storage.
    func deleteMessage(_ message: Message) async
    /// Downloads the raw EML source data for a message.
    func downloadMessageResource(message: Message, address: Address) async -> Data?
    /// Downloads all attachments for a message. Returns a map of attachmentId → AttachmentDownload.
    func downloadAttachments(_ message: Message, token: String) async -> [String: AttachmentDownload]
}
