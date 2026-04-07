//
//  AddressServiceTests.swift
//  TempBoxTests
//

import XCTest
@testable import TempBox

@MainActor
final class AddressServiceTests: XCTestCase {

    private var repo: MockAddressRepository!
    private var network: MockMailTMNetworkService!
    private var sut: AddressService!

    override func setUp() async throws {
        try await super.setUp()
        repo = MockAddressRepository()
        network = MockMailTMNetworkService()
        sut = AddressService(repository: repo, networkService: network)
    }

    override func tearDown() async throws {
        sut = nil
        network = nil
        repo = nil
        try await super.tearDown()
    }

    // MARK: - fetchAll

    func testFetchAll_delegatesToRepository() {
        let addr = makeAddress(id: "a1")
        repo.storedAddresses = [addr]
        let result = sut.fetchAll()
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, "a1")
    }

    func testFetchAll_emptyRepository_returnsEmpty() {
        XCTAssertTrue(sut.fetchAll().isEmpty)
    }

    // MARK: - isAddressUnique

    func testIsAddressUnique_noMatch_isUniqueTrue() {
        repo.storedAddresses = [makeAddress(id: "x", address: "other@test.io")]
        let (isUnique, isArchived) = sut.isAddressUnique(email: "new@test.io")
        XCTAssertTrue(isUnique)
        XCTAssertFalse(isArchived)
    }

    func testIsAddressUnique_matchExists_notArchived_isUniqueFalse() {
        repo.storedAddresses = [makeAddress(id: "x", address: "taken@test.io", isArchived: false)]
        let (isUnique, isArchived) = sut.isAddressUnique(email: "taken@test.io")
        XCTAssertFalse(isUnique)
        XCTAssertFalse(isArchived)
    }

    func testIsAddressUnique_matchExistsAndArchived_returnsArchivedTrue() {
        repo.storedAddresses = [makeAddress(id: "x", address: "arch@test.io", isArchived: true)]
        let (isUnique, isArchived) = sut.isAddressUnique(email: "arch@test.io")
        XCTAssertFalse(isUnique)
        XCTAssertTrue(isArchived)
    }

    // MARK: - addAddress

    func testAddAddress_insertsAndSaves() async {
        let account = MockMailTMNetworkService.sampleAccount(id: "new-acct")
        await sut.addAddress(account: account, token: "tok", password: "pass", name: "Alice", folder: nil)
        XCTAssertEqual(repo.insertedAddresses.count, 1)
        XCTAssertGreaterThanOrEqual(repo.saveCallCount, 1)
    }

    func testAddAddress_withName_setsName() async {
        let account = MockMailTMNetworkService.sampleAccount(id: "na-1")
        await sut.addAddress(account: account, token: "tok", password: "pass", name: "Bob", folder: nil)
        XCTAssertEqual(repo.insertedAddresses.first?.name, "Bob")
    }

    func testAddAddress_emptyName_setsNameNil() async {
        let account = MockMailTMNetworkService.sampleAccount(id: "na-2")
        await sut.addAddress(account: account, token: "tok", password: "pass", name: "  ", folder: nil)
        XCTAssertNil(repo.insertedAddresses.first?.name)
    }

    func testAddAddress_setsTokenAndPassword() async {
        let account = MockMailTMNetworkService.sampleAccount(id: "na-3")
        await sut.addAddress(account: account, token: "myToken", password: "myPass", name: "", folder: nil)
        XCTAssertEqual(repo.insertedAddresses.first?.token, "myToken")
        XCTAssertEqual(repo.insertedAddresses.first?.password, "myPass")
    }

    // MARK: - loginAndSave (V1)

    func testLoginAndSaveV1_success_insertsAddressAndReturnsTrue() async {
        network.authenticateResult = .success(MockMailTMNetworkService.sampleToken(token: "fresh-tok"))
        let v1Address = makeV1ExportAddress()
        let (success, message) = await sut.loginAndSave(v1Address: v1Address)
        XCTAssertTrue(success)
        XCTAssertEqual(message, "Success")
        XCTAssertEqual(repo.insertedAddresses.count, 1)
        XCTAssertEqual(repo.insertedAddresses.first?.token, "fresh-tok")
    }

    func testLoginAndSaveV1_networkError_returnsFalse() async {
        network.authenticateResult = .failure(MailTMError.authenticationRequired)
        let (success, message) = await sut.loginAndSave(v1Address: makeV1ExportAddress())
        XCTAssertFalse(success)
        XCTAssertFalse(message.isEmpty)
        XCTAssertTrue(repo.insertedAddresses.isEmpty)
    }

    func testLoginAndSaveV1_callsAuthenticateWithCorrectCredentials() async {
        network.authenticateResult = .success(MockMailTMNetworkService.sampleToken())
        let v1 = makeV1ExportAddress(address: "v1user@test.io", password: "v1pass")
        _ = await sut.loginAndSave(v1Address: v1)
        XCTAssertEqual(network.lastAuthenticatedAddress, "v1user@test.io")
        XCTAssertEqual(network.lastAuthenticatedPassword, "v1pass")
    }

    // MARK: - loginAndSave (V2)

    func testLoginAndSaveV2_success_insertsAndReturnsTrue() async {
        network.authenticateResult = .success(MockMailTMNetworkService.sampleToken(id: "acct-v2", token: "v2tok"))
        network.fetchAccountResult = .success(MockMailTMNetworkService.sampleAccount(id: "acct-v2"))
        let v2 = makeV2ExportAddress(email: "v2@test.io", password: "v2pass")
        let (success, message) = await sut.loginAndSave(v2Address: v2)
        XCTAssertTrue(success)
        XCTAssertEqual(message, "Success")
        XCTAssertEqual(repo.insertedAddresses.count, 1)
    }

    func testLoginAndSaveV2_authFailure_returnsFalseAndDoesNotInsert() async {
        network.authenticateResult = .failure(MailTMError.authenticationRequired)
        let (success, _) = await sut.loginAndSave(v2Address: makeV2ExportAddress())
        XCTAssertFalse(success)
        XCTAssertTrue(repo.insertedAddresses.isEmpty)
    }

    func testLoginAndSaveV2_fetchAccountFailure_returnsFalse() async {
        network.authenticateResult = .success(MockMailTMNetworkService.sampleToken())
        network.fetchAccountResult = .failure(MailTMError.notFound)
        let (success, _) = await sut.loginAndSave(v2Address: makeV2ExportAddress())
        XCTAssertFalse(success)
        XCTAssertTrue(repo.insertedAddresses.isEmpty)
    }

    func testLoginAndSaveV2_callsAuthenticateThenFetchAccount() async {
        network.authenticateResult = .success(MockMailTMNetworkService.sampleToken())
        network.fetchAccountResult = .success(MockMailTMNetworkService.sampleAccount())
        _ = await sut.loginAndSave(v2Address: makeV2ExportAddress())
        XCTAssertEqual(network.authenticateCallCount, 1)
        XCTAssertEqual(network.fetchAccountCallCount, 1)
    }

    func testLoginAndSaveV2_archived_setsArchivedFlag() async {
        network.authenticateResult = .success(MockMailTMNetworkService.sampleToken())
        network.fetchAccountResult = .success(MockMailTMNetworkService.sampleAccount())
        let v2 = makeV2ExportAddress(archived: "Yes")
        _ = await sut.loginAndSave(v2Address: v2)
        XCTAssertTrue(repo.insertedAddresses.first?.isArchived ?? false)
    }

    // MARK: - loginAndRestore

    func testLoginAndRestore_success_updatesTokenAndTogglesArchive() async {
        network.authenticateResult = .success(MockMailTMNetworkService.sampleToken(token: "restored-tok"))
        let addr = makeAddress(id: "restore-me", isArchived: true)
        let (success, msg) = await sut.loginAndRestore(addr)
        XCTAssertTrue(success)
        XCTAssertEqual(msg, "Success")
        XCTAssertEqual(addr.token, "restored-tok")
        XCTAssertFalse(addr.isArchived, "toggleArchiveStatus should have flipped isArchived")
    }

    func testLoginAndRestore_failure_returnsFalse() async {
        network.authenticateResult = .failure(MailTMError.authenticationRequired)
        let addr = makeAddress(id: "no-restore", isArchived: true)
        let (success, _) = await sut.loginAndRestore(addr)
        XCTAssertFalse(success)
        XCTAssertTrue(addr.isArchived, "isArchived should remain true on failure")
    }

    // MARK: - updateAddress

    func testUpdateAddress_callsSave() {
        let addr = makeAddress()
        let before = addr.updatedAt
        sut.updateAddress(addr)
        XCTAssertGreaterThanOrEqual(repo.saveCallCount, 1)
        XCTAssertGreaterThanOrEqual(addr.updatedAt, before)
    }

    // MARK: - toggleArchiveStatus

    func testToggleArchiveStatus_trueToFalse() async {
        let addr = makeAddress(isArchived: true)
        await sut.toggleArchiveStatus(addr)
        XCTAssertFalse(addr.isArchived)
        XCTAssertNil(addr.folder)
        XCTAssertGreaterThanOrEqual(repo.saveCallCount, 1)
    }

    func testToggleArchiveStatus_falseToTrue() async {
        let addr = makeAddress(isArchived: false)
        await sut.toggleArchiveStatus(addr)
        XCTAssertTrue(addr.isArchived)
    }

    // MARK: - deleteAddress (soft delete)

    func testDeleteAddress_setsIsDeletedAndSaves() {
        let addr = makeAddress()
        sut.deleteAddress(addr)
        XCTAssertTrue(addr.isDeleted)
        XCTAssertGreaterThanOrEqual(repo.saveCallCount, 1)
    }

    // MARK: - deleteAddressFromServer

    func testDeleteAddressFromServer_callsNetworkDeleteAndPermanentlyDeletes() async {
        let addr = makeAddress(id: "srv-del", token: "tok")
        repo.storedAddresses = [addr]
        await sut.deleteAddressFromServer(addr)
        XCTAssertEqual(network.deleteAccountCallCount, 1)
        XCTAssertEqual(network.lastDeletedAccountId, "srv-del")
        XCTAssertTrue(repo.deletedAddresses.contains(where: { $0.id == "srv-del" }))
    }

    func testDeleteAddressFromServer_networkError_stillDeletesLocally() async {
        network.deleteAccountError = MailTMError.serverError
        let addr = makeAddress(id: "srv-del-err", token: "tok")
        repo.storedAddresses = [addr]
        await sut.deleteAddressFromServer(addr)
        // Best-effort: local deletion still happens
        XCTAssertTrue(repo.deletedAddresses.contains(where: { $0.id == "srv-del-err" }))
    }

    func testDeleteAddressFromServer_noToken_skipsNetworkAndDeletesLocally() async {
        let addr = makeAddress(id: "no-tok")
        addr.token = nil
        repo.storedAddresses = [addr]
        await sut.deleteAddressFromServer(addr)
        XCTAssertEqual(network.deleteAccountCallCount, 0, "Should not call network when token is nil")
        XCTAssertTrue(repo.deletedAddresses.contains(where: { $0.id == "no-tok" }))
    }

    // MARK: - permanentlyDelete

    func testPermanentlyDelete_callsRepositoryDeleteAndSave() {
        let addr = makeAddress(id: "perm-del")
        repo.storedAddresses = [addr]
        sut.permanentlyDelete(addr)
        XCTAssertTrue(repo.deletedAddresses.contains(where: { $0.id == "perm-del" }))
        XCTAssertGreaterThanOrEqual(repo.saveCallCount, 1)
    }
}

// MARK: - Private fixture helpers

private extension AddressServiceTests {
    func makeV1ExportAddress(
        id: String = "v1-acct",
        address: String = "v1@test.io",
        password: String = "v1pass"
    ) -> ExportVersionOneAddress {
        let account = ExportedAccountVOne(
            id: id,
            address: address,
            quota: 40_000_000,
            used: 0,
            isDisabled: false,
            isDeleted: false,
            createdAt: "2024-01-01T00:00:00+00:00",
            updatedAt: "2024-01-01T00:00:00+00:00"
        )
        let user = AuthenticatedUser(account: account, password: password, token: "old-tok")
        return ExportVersionOneAddress(addressName: "V1 User", authenticatedUser: user, password: password)
    }

    func makeV2ExportAddress(
        id: String = "v2-addr",
        email: String = "v2@test.io",
        password: String = "v2pass",
        archived: String = "No"
    ) -> ExportVersionTwoAddress {
        ExportVersionTwoAddress(
            addressName: "V2 User",
            id: id,
            email: email,
            password: password,
            archived: archived,
            createdAt: "2024-01-01T00:00:00Z"
        )
    }
}
