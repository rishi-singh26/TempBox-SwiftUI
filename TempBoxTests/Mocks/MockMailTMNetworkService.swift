//
//  MockMailTMNetworkService.swift
//  TempBoxTests
//

import Foundation
@testable import TempBox

/// Configurable mock for MailTMNetworkServiceProtocol.
/// Set the Result properties before calling the SUT; inspect call-tracking properties after.
final class MockMailTMNetworkService: MailTMNetworkServiceProtocol {

    // MARK: - Sample values (shared across tests)

    static func sampleAccount(id: String = "acct-mock") -> Account {
        Account(
            id: id,
            address: "\(id)@test.io",
            quota: 40_000_000,
            used: 0,
            isDisabled: false,
            isDeleted: false,
            createdAt: "2024-01-01T00:00:00+00:00",
            updatedAt: "2024-01-01T00:00:00+00:00"
        )
    }

    static func sampleToken(id: String = "tok-1", token: String = "bearer_xyz") -> TokenResponse {
        TokenResponse(id: id, token: token)
    }

    // MARK: - Configurable results

    var fetchDomainsResult: Result<[Domain], Error> = .success([])
    var createAccountResult: Result<Account, Error> = .success(sampleAccount())
    var authenticateResult: Result<TokenResponse, Error> = .success(sampleToken())
    var fetchAccountResult: Result<Account, Error> = .success(sampleAccount())
    var deleteAccountError: Error? = nil
    var generateRandomAccountResult: Result<(Account, String), Error> = .success((sampleAccount(), "randPass"))
    var fetchMessagesResult: Result<[APIMessage], Error> = .success([])
    var fetchMessageResult: Result<APIMessage, Error> = .success(makeAPIMessage())
    var updateMessageSeenStatusResult: Result<MarkAsReadResponse, Error> = .success(MarkAsReadResponse(seen: true))
    var deleteMessageError: Error? = nil
    var fetchMessageSourceResult: Result<(APIMessage, Data), Error> = .success((makeAPIMessage(), Data()))
    var downloadMessageEMLResult: Result<Data, Error> = .success(Data("eml".utf8))
    var downloadAttachmentResult: Result<AttachmentDownload, Error> = .failure(MailTMError.notFound)

    // MARK: - Call tracking

    var fetchDomainsCallCount = 0
    var createAccountCallCount = 0
    var authenticateCallCount = 0
    var lastAuthenticatedAddress: String?
    var lastAuthenticatedPassword: String?
    var fetchAccountCallCount = 0
    var deleteAccountCallCount = 0
    var lastDeletedAccountId: String?
    var generateRandomAccountCallCount = 0
    var fetchMessagesCallCount = 0
    var lastFetchMessagesToken: String?
    var fetchMessageCallCount = 0
    var lastFetchedMessageId: String?
    var updateSeenStatusCallCount = 0
    var lastUpdateSeenId: String?
    var lastUpdateSeenValue: Bool?
    var deleteMessageCallCount = 0
    var lastDeletedMessageId: String?
    var downloadEMLCallCount = 0
    var downloadAttachmentCallCount = 0

    // MARK: - Protocol implementation

    func fetchDomains(page: Int) async throws -> [Domain] {
        fetchDomainsCallCount += 1
        return try fetchDomainsResult.get()
    }

    func createAccount(address: String, password: String) async throws -> Account {
        createAccountCallCount += 1
        return try createAccountResult.get()
    }

    func authenticate(address: String, password: String) async throws -> TokenResponse {
        authenticateCallCount += 1
        lastAuthenticatedAddress = address
        lastAuthenticatedPassword = password
        return try authenticateResult.get()
    }

    func fetchAccount(id: String, token: String) async throws -> Account {
        fetchAccountCallCount += 1
        return try fetchAccountResult.get()
    }

    func deleteAccount(id: String, token: String) async throws {
        deleteAccountCallCount += 1
        lastDeletedAccountId = id
        if let error = deleteAccountError { throw error }
    }

    func generateRandomAccount() async throws -> (Account, String) {
        generateRandomAccountCallCount += 1
        return try generateRandomAccountResult.get()
    }

    func fetchMessages(token: String, page: Int) async throws -> [APIMessage] {
        fetchMessagesCallCount += 1
        lastFetchMessagesToken = token
        return try fetchMessagesResult.get()
    }

    func fetchMessage(id: String, token: String) async throws -> APIMessage {
        fetchMessageCallCount += 1
        lastFetchedMessageId = id
        return try fetchMessageResult.get()
    }

    func updateMessageSeenStatus(id: String, token: String, seen: Bool) async throws -> MarkAsReadResponse {
        updateSeenStatusCallCount += 1
        lastUpdateSeenId = id
        lastUpdateSeenValue = seen
        return try updateMessageSeenStatusResult.get()
    }

    func deleteMessage(id: String, token: String) async throws {
        deleteMessageCallCount += 1
        lastDeletedMessageId = id
        if let error = deleteMessageError { throw error }
    }

    func fetchMessageSource(id: String, token: String) async throws -> (APIMessage, Data) {
        return try fetchMessageSourceResult.get()
    }

    func downloadMessageEML(id: String, token: String) async throws -> Data {
        downloadEMLCallCount += 1
        return try downloadMessageEMLResult.get()
    }

    func downloadAttachment(messageId: String, attachment: Attachment, token: String) async throws -> AttachmentDownload {
        downloadAttachmentCallCount += 1
        return try downloadAttachmentResult.get()
    }

    // MARK: - Helpers

    func reset() {
        fetchDomainsCallCount = 0
        createAccountCallCount = 0
        authenticateCallCount = 0
        lastAuthenticatedAddress = nil
        lastAuthenticatedPassword = nil
        fetchAccountCallCount = 0
        deleteAccountCallCount = 0
        lastDeletedAccountId = nil
        generateRandomAccountCallCount = 0
        fetchMessagesCallCount = 0
        lastFetchMessagesToken = nil
        fetchMessageCallCount = 0
        lastFetchedMessageId = nil
        updateSeenStatusCallCount = 0
        lastUpdateSeenId = nil
        lastUpdateSeenValue = nil
        deleteMessageCallCount = 0
        lastDeletedMessageId = nil
        downloadEMLCallCount = 0
        downloadAttachmentCallCount = 0
    }
}
