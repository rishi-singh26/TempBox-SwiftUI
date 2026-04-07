//
//  MockAddressRepository.swift
//  TempBoxTests
//

import Foundation
@testable import TempBox

@MainActor
final class MockAddressRepository: AddressRepositoryProtocol {

    // MARK: - Stub data
    /// Prepopulate to control what fetchAll() returns.
    var storedAddresses: [Address] = []

    // MARK: - Call tracking
    var insertedAddresses: [Address] = []
    var deletedAddresses: [Address] = []
    var saveCallCount = 0

    // MARK: - Protocol

    func fetchAll() -> [Address] {
        storedAddresses.filter { !$0.isDeleted }
    }

    func insert(_ address: Address) {
        storedAddresses.append(address)
        insertedAddresses.append(address)
    }

    func delete(_ address: Address) {
        storedAddresses.removeAll { $0.id == address.id }
        deletedAddresses.append(address)
    }

    func save() {
        saveCallCount += 1
    }

    // MARK: - Helpers

    func reset() {
        storedAddresses = []
        insertedAddresses = []
        deletedAddresses = []
        saveCallCount = 0
    }
}
