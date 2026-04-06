//
//  MailTMNetworkServiceProtocol.swift
//  TempBox
//
//  Created by Rishi Singh on 06/04/26.
//

import Foundation

protocol MailTMNetworkServiceProtocol {
    func fetchDomains(page: Int) async throws -> [Domain]
    func createAccount(address: String, password: String) async throws -> Account
    func authenticate(address: String, password: String) async throws -> TokenResponse
    func fetchAccount(id: String, token: String) async throws -> Account
    func deleteAccount(id: String, token: String) async throws
    /// Returns (account, plainTextPassword)
    func generateRandomAccount() async throws -> (Account, String)
    func fetchMessages(token: String, page: Int) async throws -> [APIMessage]
    func fetchMessage(id: String, token: String) async throws -> APIMessage
    func updateMessageSeenStatus(id: String, token: String, seen: Bool) async throws -> MarkAsReadResponse
    func deleteMessage(id: String, token: String) async throws
    /// Fetches from /sources/\(id) — returns full APIMessage + raw source Data
    func fetchMessageSource(id: String, token: String) async throws -> (APIMessage, Data)
    /// Downloads the EML file from /messages/\(id)/download
    func downloadMessageEML(id: String, token: String) async throws -> Data
    func downloadAttachment(messageId: String, attachment: Attachment, token: String) async throws -> AttachmentDownload
}
