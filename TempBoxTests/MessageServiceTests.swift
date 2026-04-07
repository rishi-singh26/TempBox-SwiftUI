//
//  MessageServiceTests.swift
//  TempBoxTests
//

import XCTest
@testable import TempBox

@MainActor
final class MessageServiceTests: XCTestCase {

    private var messageRepo: MockMessageRepository!
    private var network: MockMailTMNetworkService!
    private var sut: MessageService!

    override func setUp() async throws {
        try await super.setUp()
        messageRepo = MockMessageRepository()
        network = MockMailTMNetworkService()
        sut = MessageService(repository: messageRepo, networkService: network)
    }

    override func tearDown() async throws {
        sut = nil
        network = nil
        messageRepo = nil
        try await super.tearDown()
    }

    // MARK: - fetchMessages

    func testFetchMessages_noToken_doesNotCallNetwork() async throws {
        let addr = makeAddress(id: "no-tok")
        addr.token = nil
        try await sut.fetchMessages(for: addr)
        XCTAssertEqual(network.fetchMessagesCallCount, 0)
        XCTAssertEqual(messageRepo.upsertCallCount, 0)
    }

    func testFetchMessages_emptyToken_doesNotCallNetwork() async throws {
        let addr = makeAddress(id: "empty-tok", token: "")
        try await sut.fetchMessages(for: addr)
        XCTAssertEqual(network.fetchMessagesCallCount, 0)
    }

    func testFetchMessages_withToken_callsNetworkWithToken() async throws {
        let addr = makeAddress(id: "has-tok", token: "my-token")
        network.fetchMessagesResult = .success([makeAPIMessage()])
        messageRepo.upsertResult = []
        try await sut.fetchMessages(for: addr)
        XCTAssertEqual(network.fetchMessagesCallCount, 1)
        XCTAssertEqual(network.lastFetchMessagesToken, "my-token")
    }

    func testFetchMessages_callsUpsertWithAPIMessages() async throws {
        let apiMessages = [makeAPIMessage(id: "m1"), makeAPIMessage(id: "m2")]
        network.fetchMessagesResult = .success(apiMessages)
        messageRepo.upsertResult = []
        let addr = makeAddress(id: "up-addr", token: "tok")
        try await sut.fetchMessages(for: addr)
        XCTAssertEqual(messageRepo.upsertCallCount, 1)
        XCTAssertEqual(messageRepo.lastUpsertedAPIMessages.count, 2)
    }

    func testFetchMessages_networkError_throws() async {
        let addr = makeAddress(id: "err-addr", token: "tok")
        network.fetchMessagesResult = .failure(MailTMError.serverError)
        do {
            try await sut.fetchMessages(for: addr)
            XCTFail("Expected throw")
        } catch {
            XCTAssertTrue(error is MailTMError)
        }
    }

    // MARK: - fetchCompleteMessage

    func testFetchCompleteMessage_alreadyHasHTML_doesNotCallNetwork() async {
        let msg = makeMessage(remoteId: "m-html", html: ["<p>hi</p>"])
        await sut.fetchCompleteMessage(of: msg)
        XCTAssertEqual(network.fetchMessageCallCount, 0)
    }

    func testFetchCompleteMessage_noToken_doesNotCallNetwork() async {
        let addr = makeAddress(token: "")
        let msg = makeMessage(remoteId: "m-notok", address: addr)
        await sut.fetchCompleteMessage(of: msg)
        XCTAssertEqual(network.fetchMessageCallCount, 0)
    }

    func testFetchCompleteMessage_noHTML_callsNetwork() async {
        let addr = makeAddress(token: "tok")
        let msg = makeMessage(remoteId: "m-fetch", address: addr)
        network.fetchMessageResult = .success(makeAPIMessage(id: "m-fetch"))
        await sut.fetchCompleteMessage(of: msg)
        XCTAssertEqual(network.fetchMessageCallCount, 1)
        XCTAssertEqual(network.lastFetchedMessageId, "m-fetch")
    }

    func testFetchCompleteMessage_success_savesCalled() async {
        let addr = makeAddress(token: "tok")
        let msg = makeMessage(remoteId: "m-save", address: addr)
        network.fetchMessageResult = .success(makeAPIMessage(id: "m-save"))
        await sut.fetchCompleteMessage(of: msg)
        XCTAssertGreaterThanOrEqual(messageRepo.saveCallCount, 1)
    }

    func testFetchCompleteMessage_networkError_doesNotCrash() async {
        let addr = makeAddress(token: "tok")
        let msg = makeMessage(remoteId: "m-err", address: addr)
        network.fetchMessageResult = .failure(MailTMError.serverError)
        // Should not throw — error is caught and printed
        await sut.fetchCompleteMessage(of: msg)
        XCTAssertEqual(messageRepo.saveCallCount, 0)
    }

    // MARK: - updateSeenStatus

    func testUpdateSeenStatus_removedFromRemote_doesNotCallNetwork() async {
        let msg = makeMessage(remoteId: "gone", isRemovedFromRemote: true)
        await sut.updateSeenStatus(msg)
        XCTAssertEqual(network.updateSeenStatusCallCount, 0)
    }

    func testUpdateSeenStatus_noToken_doesNotCallNetwork() async {
        let addr = makeAddress(token: "")
        let msg = makeMessage(remoteId: "notok", address: addr)
        await sut.updateSeenStatus(msg)
        XCTAssertEqual(network.updateSeenStatusCallCount, 0)
    }

    func testUpdateSeenStatus_success_togglesSeenLocally() async {
        let addr = makeAddress(token: "tok")
        let msg = makeMessage(remoteId: "seen-msg", seen: false, address: addr)
        network.updateMessageSeenStatusResult = .success(MarkAsReadResponse(seen: true))
        await sut.updateSeenStatus(msg)
        XCTAssertTrue(msg.seen, "seen should be toggled to true")
        XCTAssertEqual(network.lastUpdateSeenId, "seen-msg")
    }

    func testUpdateSeenStatus_callsNetworkWithToggledValue() async {
        let addr = makeAddress(token: "tok")
        let msg = makeMessage(remoteId: "toggle-m", seen: false, address: addr)
        network.updateMessageSeenStatusResult = .success(MarkAsReadResponse(seen: true))
        await sut.updateSeenStatus(msg)
        // The network call passes !message.seen (toggled value)
        XCTAssertEqual(network.lastUpdateSeenValue, true)
    }

    func testUpdateSeenStatus_notFoundError_stillTogglesSeen() async {
        let addr = makeAddress(token: "tok")
        let msg = makeMessage(remoteId: "not-found-m", seen: false, address: addr)
        network.updateMessageSeenStatusResult = .failure(MailTMError.notFound)
        await sut.updateSeenStatus(msg)
        // notFound = message deleted on server, still update locally
        XCTAssertTrue(msg.seen, "Seen should be toggled even on notFound error")
    }

    func testUpdateSeenStatus_otherError_doesNotToggle() async {
        let addr = makeAddress(token: "tok")
        let msg = makeMessage(remoteId: "other-err", seen: false, address: addr)
        network.updateMessageSeenStatusResult = .failure(MailTMError.serverError)
        await sut.updateSeenStatus(msg)
        XCTAssertFalse(msg.seen, "Seen should NOT toggle on non-notFound errors")
    }

    // MARK: - deleteMessage

    func testDeleteMessage_noToken_doesNotCallNetwork() async {
        let addr = makeAddress(token: "")
        let msg = makeMessage(address: addr)
        await sut.deleteMessage(msg)
        XCTAssertEqual(network.deleteMessageCallCount, 0)
        XCTAssertTrue(messageRepo.deletedMessages.isEmpty)
    }

    func testDeleteMessage_success_callsNetworkAndDeletesLocally() async {
        let addr = makeAddress(token: "tok")
        let msg = makeMessage(remoteId: "del-msg", address: addr)
        await sut.deleteMessage(msg)
        XCTAssertEqual(network.deleteMessageCallCount, 1)
        XCTAssertEqual(network.lastDeletedMessageId, "del-msg")
        XCTAssertTrue(messageRepo.deletedMessages.contains(where: { $0.remoteId == "del-msg" }))
    }

    func testDeleteMessage_networkError_doesNotDeleteLocally() async {
        let addr = makeAddress(token: "tok")
        let msg = makeMessage(remoteId: "no-del", address: addr)
        network.deleteMessageError = MailTMError.serverError
        await sut.deleteMessage(msg)
        XCTAssertTrue(messageRepo.deletedMessages.isEmpty,
                      "Should not delete locally when network fails")
    }

    // MARK: - downloadMessageResource

    func testDownloadMessageResource_noToken_returnsNil() async {
        let addr = makeAddress(token: "")
        let msg = makeMessage(address: addr)
        let data = await sut.downloadMessageResource(message: msg, address: addr)
        XCTAssertNil(data)
        XCTAssertEqual(network.downloadEMLCallCount, 0)
    }

    func testDownloadMessageResource_success_returnsData() async {
        let addr = makeAddress(token: "tok")
        let msg = makeMessage(remoteId: "eml-msg", address: addr)
        let expected = Data("EML content".utf8)
        network.downloadMessageEMLResult = .success(expected)
        let data = await sut.downloadMessageResource(message: msg, address: addr)
        XCTAssertEqual(data, expected)
        XCTAssertEqual(network.downloadEMLCallCount, 1)
    }

    func testDownloadMessageResource_networkError_returnsNil() async {
        let addr = makeAddress(token: "tok")
        let msg = makeMessage(address: addr)
        network.downloadMessageEMLResult = .failure(MailTMError.notFound)
        let data = await sut.downloadMessageResource(message: msg, address: addr)
        XCTAssertNil(data)
    }

    // MARK: - downloadAttachments

    func testDownloadAttachments_noAttachments_returnsEmptyDict() async {
        let msg = makeMessage()
        let result = await sut.downloadAttachments(msg, token: "tok")
        XCTAssertTrue(result.isEmpty)
    }

    func testDownloadAttachments_networkError_omitsFromResult() async {
        let attachment = makeAttachment(id: "att-1")
        let msg = makeMessage(attachments: [attachment])
        network.downloadAttachmentResult = .failure(MailTMError.notFound)
        let result = await sut.downloadAttachments(msg, token: "tok")
        XCTAssertTrue(result.isEmpty, "Failed attachment should not appear in result")
    }
}

// MARK: - Private fixture helpers

private extension MessageServiceTests {
    func makeMessage(
        remoteId: String = "msg-default",
        seen: Bool = false,
        html: [String]? = nil,
        isRemovedFromRemote: Bool = false,
        attachments: [Attachment]? = nil,
        address: Address? = nil
    ) -> Message {
        let msg = Message(
            remoteId: remoteId,
            accountId: "acct-1",
            msgid: "<\(remoteId)@test.io>",
            fromName: "Sender",
            fromAddress: "from@test.io",
            to: "::to@test.io",
            subject: "Subject",
            html: html,
            seen: seen,
            isDeleted: false,
            hasAttachments: attachments != nil,
            attachments: attachments,
            size: 256,
            downloadUrl: "/download/\(remoteId)",
            sourceUrl: "/source/\(remoteId)",
            createdAt: "2024-01-15T10:00:00Z",
            updatedAt: "2024-01-15T10:00:00Z"
        )
        msg.isRemovedFromRemote = isRemovedFromRemote
        msg.address = address
        return msg
    }

    func makeAttachment(id: String = "att-1") -> Attachment {
        Attachment(
            id: id,
            filename: "\(id).pdf",
            contentType: "application/pdf",
            disposition: "attachment",
            transferEncoding: "base64",
            related: false,
            size: 1024,
            downloadUrl: "/attachment/\(id)"
        )
    }
}
