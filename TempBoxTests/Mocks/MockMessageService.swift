//
//  MockMessageService.swift
//  TempBoxTests
//

import Foundation
@testable import TempBox

@MainActor
final class MockMessageService: MessageServiceProtocol {

    // MARK: - Stubs
    var fetchMessagesError: Error? = nil
    var downloadResourceResult: Data? = nil
    var downloadAttachmentsResult: [String: AttachmentDownload] = [:]

    // MARK: - Call tracking
    var fetchMessagesCallCount = 0
    var lastFetchMessagesAddress: Address?
    var fetchCompleteMessageCallCount = 0
    var fetchCompleteMessagesCallCount = 0
    var updateSeenStatusCallCount = 0
    var lastUpdateSeenMessage: Message?
    var deleteMessageCallCount = 0
    var lastDeletedMessage: Message?
    var downloadResourceCallCount = 0
    var downloadAttachmentsCallCount = 0

    // MARK: - Protocol

    func fetchMessages(for address: Address) async throws {
        fetchMessagesCallCount += 1
        lastFetchMessagesAddress = address
        if let error = fetchMessagesError { throw error }
    }

    func fetchCompleteMessage(of message: Message) async {
        fetchCompleteMessageCallCount += 1
    }

    func fetchCompleteMessages(for messages: [Message], address: Address) async {
        fetchCompleteMessagesCallCount += 1
    }

    func updateSeenStatus(_ message: Message) async {
        updateSeenStatusCallCount += 1
        lastUpdateSeenMessage = message
    }

    func deleteMessage(_ message: Message) async {
        deleteMessageCallCount += 1
        lastDeletedMessage = message
    }

    func downloadMessageResource(message: Message, address: Address) async -> Data? {
        downloadResourceCallCount += 1
        return downloadResourceResult
    }

    func downloadAttachments(_ message: Message, token: String) async -> [String: AttachmentDownload] {
        downloadAttachmentsCallCount += 1
        return downloadAttachmentsResult
    }

    // MARK: - Helpers

    func reset() {
        fetchMessagesError = nil
        downloadResourceResult = nil
        downloadAttachmentsResult = [:]
        fetchMessagesCallCount = 0
        lastFetchMessagesAddress = nil
        fetchCompleteMessageCallCount = 0
        fetchCompleteMessagesCallCount = 0
        updateSeenStatusCallCount = 0
        lastUpdateSeenMessage = nil
        deleteMessageCallCount = 0
        lastDeletedMessage = nil
        downloadResourceCallCount = 0
        downloadAttachmentsCallCount = 0
    }
}
