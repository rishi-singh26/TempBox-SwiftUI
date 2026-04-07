//
//  AddressStoreTests.swift
//  TempBoxTests
//

import XCTest
@testable import TempBox

@MainActor
final class AddressStoreTests: XCTestCase {

    private var addressService: MockAddressService!
    private var messageService: MockMessageService!

    override func setUp() async throws {
        try await super.setUp()
        addressService = MockAddressService()
        messageService = MockMessageService()
    }

    override func tearDown() async throws {
        addressService = nil
        messageService = nil
        try await super.tearDown()
    }

    /// Creates an AddressStore and immediately calls fetchAddresses()
    /// so tests have deterministic state without relying on the init Task.
    private func makeSUT() -> AddressStore {
        AddressStore(addressService: addressService, messageService: messageService)
    }

    // MARK: - fetchAddresses

    func testFetchAddresses_callsAddressServiceFetchAll() async {
        let sut = makeSUT()
        addressService.addresses = [makeAddress(id: "a1"), makeAddress(id: "a2")]
        await sut.fetchAddresses()
        XCTAssertGreaterThanOrEqual(addressService.fetchAllCallCount, 1)
    }

    func testFetchAddresses_setsIsLoadingFalseWhenDone() async {
        let sut = makeSUT()
        await sut.fetchAddresses()
        XCTAssertFalse(sut.isLoading)
    }

    func testFetchAddresses_withArchivedAddress_doesNotFetchMessages() async {
        let archived = makeAddress(id: "arch", isArchived: true, token: "tok")
        addressService.addresses = [archived]
        let sut = makeSUT()
        await sut.fetchAddresses()
        // Archived addresses are skipped in fetchMessagesForAllAddresses
        XCTAssertEqual(messageService.fetchMessagesCallCount, 0)
    }

    func testFetchAddresses_withNoTokenAddress_doesNotFetchMessages() async {
        let noTok = makeAddress(id: "notok", token: "")
        addressService.addresses = [noTok]
        let sut = makeSUT()
        await sut.fetchAddresses()
        XCTAssertEqual(messageService.fetchMessagesCallCount, 0)
    }

    // MARK: - fetchMessages(for address:)

    func testFetchMessages_withToken_callsMessageService() async {
        let addr = makeAddress(id: "fetch-addr", token: "tok")
        let sut = makeSUT()
        await sut.fetchMessages(for: addr)
        XCTAssertEqual(messageService.fetchMessagesCallCount, 1)
        XCTAssertEqual(messageService.lastFetchMessagesAddress?.id, "fetch-addr")
    }

    func testFetchMessages_noToken_doesNotCallMessageService() async {
        let addr = makeAddress(id: "no-tok", token: "")
        let sut = makeSUT()
        await sut.fetchMessages(for: addr)
        XCTAssertEqual(messageService.fetchMessagesCallCount, 0)
    }

    func testFetchMessages_setsMessageStoreIsFetchingTrueThenFalse() async {
        let addr = makeAddress(id: "ms-addr", token: "tok")
        let sut = makeSUT()
        await sut.fetchMessages(for: addr)
        // After completion, isFetching should be false
        XCTAssertEqual(sut.messageStore[addr.id]?.isFetching, false)
    }

    func testFetchMessages_networkError_setsErrorInMessageStore() async {
        messageService.fetchMessagesError = MailTMError.serverError
        let addr = makeAddress(id: "err-addr", token: "tok")
        let sut = makeSUT()
        await sut.fetchMessages(for: addr)
        let storeEntry = sut.messageStore[addr.id]
        XCTAssertFalse(storeEntry?.isFetching ?? true)
        XCTAssertNotNil(storeEntry?.error)
    }

    func testFetchMessages_success_clearsErrorInMessageStore() async {
        let addr = makeAddress(id: "ok-addr", token: "tok")
        let sut = makeSUT()
        await sut.fetchMessages(for: addr)
        XCTAssertNil(sut.messageStore[addr.id]?.error)
    }

    // MARK: - fetchMessages(for addressId:)

    func testFetchMessagesByAddressId_matchingAddress_callsService() async {
        let addr = makeAddress(id: "by-id", token: "tok")
        addressService.addresses = [addr]
        let sut = makeSUT()
        await sut.fetchAddresses()
        messageService.reset()
        await sut.fetchMessages(for: "by-id")
        XCTAssertEqual(messageService.fetchMessagesCallCount, 1)
    }

    func testFetchMessagesByAddressId_noMatch_doesNotCallService() async {
        addressService.addresses = [makeAddress(id: "real-id", token: "tok")]
        let sut = makeSUT()
        await sut.fetchAddresses()
        messageService.reset()
        await sut.fetchMessages(for: "nonexistent-id")
        XCTAssertEqual(messageService.fetchMessagesCallCount, 0)
    }

    // MARK: - fetchCompleteMessage

    func testFetchCompleteMessage_setsLoadingAndDelegates() async {
        let msg = makeTestMessage()
        let sut = makeSUT()
        await sut.fetchCompleteMessage(of: msg)
        XCTAssertEqual(messageService.fetchCompleteMessageCallCount, 1)
        XCTAssertFalse(sut.loadingCompleteMessage)
    }

    // MARK: - selectedMessage didSet → updateSeenStatus

    func testSelectedMessage_unreadMessage_triggersUpdateSeenStatus() async {
        let sut = makeSUT()
        let msg = makeTestMessage(seen: false)
        sut.selectedMessage = msg
        // The didSet fires a Task — yield to allow it to run
        await Task.yield()
        XCTAssertGreaterThanOrEqual(messageService.updateSeenStatusCallCount, 1)
    }

    func testSelectedMessage_alreadyRead_doesNotTriggerUpdateSeenStatus() async {
        let sut = makeSUT()
        let msg = makeTestMessage(seen: true)
        sut.selectedMessage = msg
        await Task.yield()
        XCTAssertEqual(messageService.updateSeenStatusCallCount, 0)
    }

    func testSelectedAddress_willSet_clearsSelectedMessage() {
        let sut = makeSUT()
        sut.selectedMessage = makeTestMessage()
        sut.selectedAddress = makeAddress(id: "new-addr")
        XCTAssertNil(sut.selectedMessage)
    }

    // MARK: - addAddress

    func testAddAddress_delegatesToServiceAndRefetches() async {
        let sut = makeSUT()
        let account = MockMailTMNetworkService.sampleAccount()
        await sut.addAddress(account: account, token: "tok", password: "pass", name: "Test", folder: nil)
        XCTAssertEqual(addressService.addAddressCallCount, 1)
        XCTAssertGreaterThanOrEqual(addressService.fetchAllCallCount, 1)
    }

    // MARK: - loginAndSave V1

    func testLoginAndSaveV1_success_refetchesAddresses() async {
        addressService.loginAndSaveV1Result = (true, "Success")
        let sut = makeSUT()
        let v1 = makeV1ExportAddress()
        let (success, _) = await sut.loginAndSave(v1Address: v1)
        XCTAssertTrue(success)
        XCTAssertGreaterThanOrEqual(addressService.fetchAllCallCount, 2)
    }

    func testLoginAndSaveV1_failure_doesNotRefetch() async {
        addressService.loginAndSaveV1Result = (false, "Auth failed")
        let sut = makeSUT()
        let fetchCountBefore = addressService.fetchAllCallCount
        _ = await sut.loginAndSave(v1Address: makeV1ExportAddress())
        XCTAssertEqual(addressService.fetchAllCallCount, fetchCountBefore)
    }

    // MARK: - loginAndSave V2

    func testLoginAndSaveV2_success_refetchesAddresses() async {
        addressService.loginAndSaveV2Result = (true, "Success")
        let sut = makeSUT()
        let (success, _) = await sut.loginAndSave(v2Address: makeV2ExportAddress())
        XCTAssertTrue(success)
        XCTAssertGreaterThanOrEqual(addressService.fetchAllCallCount, 2)
    }

    // MARK: - deleteAddress

    func testDeleteAddress_delegatesToServiceAndRefetches() async {
        let sut = makeSUT()
        let addr = makeAddress(id: "del-addr")
        await sut.deleteAddress(addr)
        XCTAssertEqual(addressService.deleteAddressCallCount, 1)
        XCTAssertGreaterThanOrEqual(addressService.fetchAllCallCount, 1)
    }

    // MARK: - deleteAddressFromServer

    func testDeleteAddressFromServer_delegatesToService() async {
        let sut = makeSUT()
        await sut.deleteAddressFromServer(makeAddress())
        XCTAssertEqual(addressService.deleteAddressFromServerCallCount, 1)
    }

    // MARK: - permanentlyDelete

    func testPermanentlyDelete_delegatesToService() async {
        let sut = makeSUT()
        await sut.permanentlyDelete(makeAddress())
        XCTAssertEqual(addressService.permanentlyDeleteCallCount, 1)
    }

    // MARK: - toggleArchiveStatus

    func testToggleArchiveStatus_delegatesToService() async {
        let sut = makeSUT()
        await sut.toggleArchiveStatus(makeAddress())
        XCTAssertEqual(addressService.toggleArchiveCallCount, 1)
    }

    // MARK: - deleteMessage

    func testDeleteMessage_delegatesToMessageService() async {
        let sut = makeSUT()
        let msg = makeTestMessage()
        await sut.deleteMessage(message: msg)
        XCTAssertEqual(messageService.deleteMessageCallCount, 1)
        XCTAssertTrue(messageService.lastDeletedMessage === msg)
    }

    // MARK: - updateMessageSeenStatus

    func testUpdateMessageSeenStatus_delegatesToService() async {
        let sut = makeSUT()
        let msg = makeTestMessage()
        await sut.updateMessageSeenStatus(messageData: msg)
        XCTAssertEqual(messageService.updateSeenStatusCallCount, 1)
    }

    // MARK: - downloadMessageResource

    func testDownloadMessageResource_returnsServiceResult() async {
        messageService.downloadResourceResult = Data("content".utf8)
        let sut = makeSUT()
        let addr = makeAddress()
        let msg = makeTestMessage()
        let data = await sut.downloadMessageResource(message: msg, address: addr)
        XCTAssertEqual(data, Data("content".utf8))
        XCTAssertEqual(messageService.downloadResourceCallCount, 1)
    }

    // MARK: - isAddressUnique

    func testIsAddressUnique_delegatesToService() {
        addressService.isAddressUniqueResult = (false, true)
        let sut = makeSUT()
        let (isUnique, isArchived) = sut.isAddressUnique(email: "test@test.io")
        XCTAssertFalse(isUnique)
        XCTAssertTrue(isArchived)
        XCTAssertEqual(addressService.lastUniqueCheckEmail, "test@test.io")
    }

    // MARK: - updateMessageStore

    func testUpdateMessageStore_setsEntry() {
        let addr = makeAddress(id: "ms-key")
        let sut = makeSUT()
        sut.updateMessageStore(for: addr, store: MessageStore(isFetching: true, error: "oops"))
        XCTAssertEqual(sut.messageStore[addr.id]?.isFetching, true)
        XCTAssertEqual(sut.messageStore[addr.id]?.error, "oops")
    }

    // MARK: - show / clearError

    func testShowError_setsMessageAndFlag() {
        let sut = makeSUT()
        sut.show(error: "Something went wrong")
        XCTAssertEqual(sut.errorMessage, "Something went wrong")
        XCTAssertTrue(sut.showError)
    }

    func testClearError_resetsMessageAndFlag() {
        let sut = makeSUT()
        sut.show(error: "err")
        sut.clearError()
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.showError)
    }

    // MARK: - updateMessageSelection

    func testUpdateMessageSelection_withMessage_setsAddressAndMessage() async {
        let addr = makeAddress(id: "sel-addr")
        let msg = makeTestMessage()
        msg.address = addr
        let sut = makeSUT()
        await sut.updateMessageSelection(message: msg)
        XCTAssertEqual(sut.selectedAddress?.id, "sel-addr")
        // selectedMessage is set via didSet which also calls updateSeenStatus via Task
    }

    func testUpdateMessageSelection_nilMessage_noChange() async {
        let sut = makeSUT()
        await sut.updateMessageSelection(message: nil)
        XCTAssertNil(sut.selectedAddress)
    }
}

// MARK: - Private fixture helpers

private extension AddressStoreTests {
    func makeTestMessage(seen: Bool = false) -> Message {
        Message(
            remoteId: "store-msg-\(UUID().uuidString)",
            accountId: "acct-1",
            msgid: "<id@test.io>",
            fromName: "Sender",
            fromAddress: "from@test.io",
            to: "::to@test.io",
            subject: "Test",
            seen: seen,
            isDeleted: false,
            hasAttachments: false,
            size: 100,
            downloadUrl: "/dl",
            sourceUrl: "/src",
            createdAt: "2024-01-15T10:00:00Z",
            updatedAt: "2024-01-15T10:00:00Z"
        )
    }

    func makeV1ExportAddress() -> ExportVersionOneAddress {
        let account = ExportedAccountVOne(
            id: "v1-id", address: "v1@test.io", quota: 0, used: 0,
            isDisabled: false, isDeleted: false,
            createdAt: "2024-01-01T00:00:00+00:00",
            updatedAt: "2024-01-01T00:00:00+00:00"
        )
        return ExportVersionOneAddress(
            addressName: "V1",
            authenticatedUser: AuthenticatedUser(account: account, password: "p", token: "t"),
            password: "p"
        )
    }

    func makeV2ExportAddress() -> ExportVersionTwoAddress {
        ExportVersionTwoAddress(
            addressName: "V2", id: "v2-id", email: "v2@test.io",
            password: "p", archived: "No", createdAt: "2024-01-01T00:00:00Z"
        )
    }
}
