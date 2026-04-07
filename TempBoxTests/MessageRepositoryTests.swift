//
//  MessageRepositoryTests.swift
//  TempBoxTests
//

import XCTest
import SwiftData
@testable import TempBox

@MainActor
final class MessageRepositoryTests: XCTestCase {

    private var container: ModelContainer!
    private var addressRepo: AddressRepository!
    private var sut: MessageRepository!
    private var testAddress: Address!

    override func setUp() async throws {
        try await super.setUp()
        container = try makeTestModelContainer()
        addressRepo = AddressRepository(modelContext: container.mainContext)
        sut = MessageRepository(modelContext: container.mainContext)

        // Seed a single Address that messages will be attached to
        testAddress = makeAddress(id: "test-addr")
        addressRepo.insert(testAddress)
        addressRepo.save()
    }

    override func tearDown() async throws {
        testAddress = nil
        sut = nil
        addressRepo = nil
        container = nil
        try await super.tearDown()
    }

    // MARK: - upsert: new messages

    func testUpsert_newMessages_allInserted() {
        let apiMessages = [makeAPIMessage(id: "m1"), makeAPIMessage(id: "m2"), makeAPIMessage(id: "m3")]
        let result = sut.upsert(apiMessages, for: testAddress)
        sut.save()
        XCTAssertEqual(result.count, 3)
    }

    func testUpsert_newMessages_assignedToAddress() {
        let result = sut.upsert([makeAPIMessage(id: "m1")], for: testAddress)
        XCTAssertEqual(result.first?.address?.id, testAddress.id)
    }

    func testUpsert_newMessages_remoteIdMatches() {
        let result = sut.upsert([makeAPIMessage(id: "remote-42")], for: testAddress)
        XCTAssertEqual(result.first?.remoteId, "remote-42")
    }

    func testUpsert_newMessages_seenStatusPreserved() {
        let unread = makeAPIMessage(id: "m-unread", seen: false)
        let read = makeAPIMessage(id: "m-read", seen: true)
        let result = sut.upsert([unread, read], for: testAddress)
        let unreadMsg = result.first(where: { $0.remoteId == "m-unread" })
        let readMsg = result.first(where: { $0.remoteId == "m-read" })
        XCTAssertEqual(unreadMsg?.seen, false)
        XCTAssertEqual(readMsg?.seen, true)
    }

    func testUpsert_emptyArray_returnsEmpty() {
        let result = sut.upsert([], for: testAddress)
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - upsert: update existing messages

    func testUpsert_existingMessage_updatesSeenStatus() {
        // First upsert: insert as unseen
        _ = sut.upsert([makeAPIMessage(id: "msg-upd", seen: false)], for: testAddress)
        sut.save()

        // Second upsert: mark as seen
        let result = sut.upsert([makeAPIMessage(id: "msg-upd", seen: true)], for: testAddress)
        sut.save()

        XCTAssertEqual(result.count, 1)
        XCTAssertTrue(result.first?.seen ?? false, "Existing message should have seen updated to true")
    }

    func testUpsert_existingMessage_doesNotCreateDuplicate() {
        _ = sut.upsert([makeAPIMessage(id: "msg-dup")], for: testAddress)
        sut.save()
        _ = sut.upsert([makeAPIMessage(id: "msg-dup")], for: testAddress)
        sut.save()

        let allMessages = testAddress.messages ?? []
        let matching = allMessages.filter { $0.remoteId == "msg-dup" }
        XCTAssertEqual(matching.count, 1, "Should not insert duplicate message")
    }

    func testUpsert_mixedNewAndExisting_correctCounts() {
        // Seed one existing message
        _ = sut.upsert([makeAPIMessage(id: "old-msg")], for: testAddress)
        sut.save()

        // Next upsert includes the existing + two new
        let next = sut.upsert([
            makeAPIMessage(id: "old-msg"),
            makeAPIMessage(id: "new-1"),
            makeAPIMessage(id: "new-2")
        ], for: testAddress)
        sut.save()

        XCTAssertEqual(next.count, 3)
    }

    // MARK: - upsert: isRemovedFromRemote flag

    func testUpsert_messageAbsentFromAPI_markedAsRemovedFromRemote() {
        // Seed message
        _ = sut.upsert([makeAPIMessage(id: "gone")], for: testAddress)
        sut.save()

        // Next sync: "gone" is not in the payload
        _ = sut.upsert([makeAPIMessage(id: "still-here")], for: testAddress)
        sut.save()

        let goneMsg = testAddress.messages?.first(where: { $0.remoteId == "gone" })
        XCTAssertNotNil(goneMsg)
        XCTAssertTrue(goneMsg?.isRemovedFromRemote ?? false,
                      "Message absent from server should have isRemovedFromRemote = true")
    }

    func testUpsert_messagePresentInAPI_notMarkedAsRemoved() {
        _ = sut.upsert([makeAPIMessage(id: "present")], for: testAddress)
        sut.save()

        _ = sut.upsert([makeAPIMessage(id: "present")], for: testAddress)
        sut.save()

        let msg = testAddress.messages?.first(where: { $0.remoteId == "present" })
        XCTAssertFalse(msg?.isRemovedFromRemote ?? true,
                       "Present message should NOT be marked as removed")
    }

    func testUpsert_multipleMessagesRemovedFromRemote_allFlagged() {
        _ = sut.upsert([
            makeAPIMessage(id: "gone-1"),
            makeAPIMessage(id: "gone-2"),
            makeAPIMessage(id: "stay")
        ], for: testAddress)
        sut.save()

        // Only "stay" remains in next payload
        _ = sut.upsert([makeAPIMessage(id: "stay")], for: testAddress)
        sut.save()

        let gone1 = testAddress.messages?.first(where: { $0.remoteId == "gone-1" })
        let gone2 = testAddress.messages?.first(where: { $0.remoteId == "gone-2" })
        let stay = testAddress.messages?.first(where: { $0.remoteId == "stay" })

        XCTAssertTrue(gone1?.isRemovedFromRemote ?? false)
        XCTAssertTrue(gone2?.isRemovedFromRemote ?? false)
        XCTAssertFalse(stay?.isRemovedFromRemote ?? true)
    }

    func testUpsert_emptyPayload_allExistingMarkedRemoved() {
        _ = sut.upsert([makeAPIMessage(id: "m1"), makeAPIMessage(id: "m2")], for: testAddress)
        sut.save()

        // Empty sync — server returned no messages
        _ = sut.upsert([], for: testAddress)
        sut.save()

        let messages = testAddress.messages ?? []
        XCTAssertTrue(messages.allSatisfy { $0.isRemovedFromRemote },
                      "All messages should be flagged as removed from remote")
    }

    // MARK: - delete

    func testDelete_removesMessageFromContext() {
        let result = sut.upsert([makeAPIMessage(id: "del-me")], for: testAddress)
        sut.save()
        XCTAssertEqual(testAddress.messages?.count, 1)

        let msg = result.first!
        sut.delete(msg)
        sut.save()

        let remaining = testAddress.messages?.filter { !$0.isDeleted } ?? []
        // After hard delete from context, message should no longer be fetchable
        let descriptor = FetchDescriptor<Message>()
        let all = (try? container.mainContext.fetch(descriptor)) ?? []
        XCTAssertFalse(all.contains(where: { $0.remoteId == "del-me" }),
                       "Deleted message should be gone from context")
    }

    func testDelete_onlyRemovesTargetMessage() {
        _ = sut.upsert([makeAPIMessage(id: "keep"), makeAPIMessage(id: "del")], for: testAddress)
        sut.save()

        let del = testAddress.messages!.first(where: { $0.remoteId == "del" })!
        sut.delete(del)
        sut.save()

        let descriptor = FetchDescriptor<Message>()
        let all = (try? container.mainContext.fetch(descriptor)) ?? []
        XCTAssertTrue(all.contains(where: { $0.remoteId == "keep" }))
        XCTAssertFalse(all.contains(where: { $0.remoteId == "del" }))
    }

    // MARK: - save

    func testSave_persistsUpsertedMessages() {
        _ = sut.upsert([makeAPIMessage(id: "saved-msg")], for: testAddress)
        sut.save()

        let sut2 = MessageRepository(modelContext: container.mainContext)
        _ = sut2  // Use a fresh repo reference to confirm data is present in same context
        let descriptor = FetchDescriptor<Message>()
        let all = (try? container.mainContext.fetch(descriptor)) ?? []
        XCTAssertTrue(all.contains(where: { $0.remoteId == "saved-msg" }))
    }

    // MARK: - Message fields from APIMessage

    func testUpsert_messageFields_mappedCorrectly() {
        let api = makeAPIMessage(id: "field-msg", subject: "Hello World")
        let result = sut.upsert([api], for: testAddress)
        sut.save()

        let msg = result.first!
        XCTAssertEqual(msg.remoteId, "field-msg")
        XCTAssertEqual(msg.subject, "Hello World")
        XCTAssertEqual(msg.fromAddress, "from@test.io")
        XCTAssertEqual(msg.accountId, "acct-1")
        XCTAssertFalse(msg.isRemovedFromRemote)
    }
}
