//
//  MockAddressService.swift
//  TempBoxTests
//

import Foundation
@testable import TempBox

@MainActor
final class MockAddressService: AddressServiceProtocol {

    // MARK: - Stubs
    var addresses: [Address] = []
    var isAddressUniqueResult: (Bool, Bool) = (true, false)
    var loginAndSaveV1Result: (Bool, String) = (true, "Success")
    var loginAndSaveV2Result: (Bool, String) = (true, "Success")
    var loginAndRestoreResult: (Bool, String) = (true, "Success")

    // MARK: - Call tracking
    var fetchAllCallCount = 0
    var isAddressUniqueCallCount = 0
    var lastUniqueCheckEmail: String?
    var addAddressCallCount = 0
    var loginAndSaveV1CallCount = 0
    var loginAndSaveV2CallCount = 0
    var loginAndRestoreCallCount = 0
    var updateAddressCallCount = 0
    var deleteAddressCallCount = 0
    var deleteAddressFromServerCallCount = 0
    var permanentlyDeleteCallCount = 0
    var toggleArchiveCallCount = 0

    // MARK: - Protocol

    func fetchAll() -> [Address] {
        fetchAllCallCount += 1
        return addresses
    }

    func isAddressUnique(email: String) -> (Bool, Bool) {
        isAddressUniqueCallCount += 1
        lastUniqueCheckEmail = email
        return isAddressUniqueResult
    }

    func addAddress(account: Account, token: String, password: String, name: String, folder: Folder?) async {
        addAddressCallCount += 1
    }

    func loginAndSave(v1Address: ExportVersionOneAddress) async -> (Bool, String) {
        loginAndSaveV1CallCount += 1
        return loginAndSaveV1Result
    }

    func loginAndSave(v2Address: ExportVersionTwoAddress) async -> (Bool, String) {
        loginAndSaveV2CallCount += 1
        return loginAndSaveV2Result
    }

    func loginAndRestore(_ address: Address) async -> (Bool, String) {
        loginAndRestoreCallCount += 1
        return loginAndRestoreResult
    }

    func updateAddress(_ address: Address) {
        updateAddressCallCount += 1
    }

    func deleteAddress(_ address: Address) {
        deleteAddressCallCount += 1
    }

    func deleteAddressFromServer(_ address: Address) async {
        deleteAddressFromServerCallCount += 1
    }

    func permanentlyDelete(_ address: Address) {
        permanentlyDeleteCallCount += 1
    }

    func toggleArchiveStatus(_ address: Address) async {
        toggleArchiveCallCount += 1
    }

    // MARK: - Helpers

    func reset() {
        addresses = []
        fetchAllCallCount = 0
        isAddressUniqueCallCount = 0
        lastUniqueCheckEmail = nil
        addAddressCallCount = 0
        loginAndSaveV1CallCount = 0
        loginAndSaveV2CallCount = 0
        loginAndRestoreCallCount = 0
        updateAddressCallCount = 0
        deleteAddressCallCount = 0
        deleteAddressFromServerCallCount = 0
        permanentlyDeleteCallCount = 0
        toggleArchiveCallCount = 0
    }
}
