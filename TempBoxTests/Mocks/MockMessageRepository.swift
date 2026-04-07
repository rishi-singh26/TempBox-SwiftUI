//
//  MockMessageRepository.swift
//  TempBoxTests
//

import Foundation
@testable import TempBox

@MainActor
final class MockMessageRepository: MessageRepositoryProtocol {

    // MARK: - Configurable stub
    /// Set this to control what upsert() returns.
    var upsertResult: [Message] = []

    // MARK: - Call tracking
    var upsertCallCount = 0
    var lastUpsertedAPIMessages: [APIMessage] = []
    var lastUpsertAddress: Address?
    var deletedMessages: [Message] = []
    var saveCallCount = 0

    // MARK: - Protocol

    func upsert(_ apiMessages: [APIMessage], for address: Address) -> [Message] {
        upsertCallCount += 1
        lastUpsertedAPIMessages = apiMessages
        lastUpsertAddress = address
        return upsertResult
    }

    func delete(_ message: Message) {
        deletedMessages.append(message)
    }

    func save() {
        saveCallCount += 1
    }

    // MARK: - Helpers

    func reset() {
        upsertResult = []
        upsertCallCount = 0
        lastUpsertedAPIMessages = []
        lastUpsertAddress = nil
        deletedMessages = []
        saveCallCount = 0
    }
}
