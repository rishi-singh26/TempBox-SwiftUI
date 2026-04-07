//
//  AddressRepositoryTests.swift
//  TempBoxTests
//

import XCTest
import SwiftData
@testable import TempBox

@MainActor
final class AddressRepositoryTests: XCTestCase {

    private var container: ModelContainer!
    private var sut: AddressRepository!

    override func setUp() async throws {
        try await super.setUp()
        container = try makeTestModelContainer()
        sut = AddressRepository(modelContext: container.mainContext)
    }

    override func tearDown() async throws {
        sut = nil
        container = nil
        try await super.tearDown()
    }

    // MARK: - fetchAll

    func testFetchAll_emptyStore_returnsEmptyArray() {
        XCTAssertTrue(sut.fetchAll().isEmpty)
    }

    func testFetchAll_afterInsert_returnsAddress() {
        let addr = makeAddress()
        sut.insert(addr)
        sut.save()
        let result = sut.fetchAll()
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, "addr-1")
    }

    func testFetchAll_excludesDeletedAddresses() {
        let active = makeAddress(id: "active-1")
        let deleted = makeAddress(id: "deleted-1", isDeleted: true)
        sut.insert(active)
        sut.insert(deleted)
        sut.save()
        let result = sut.fetchAll()
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, "active-1")
    }

    func testFetchAll_multipleActive_excludesOnlyDeleted() {
        for i in 0..<5 {
            sut.insert(makeAddress(id: "addr-\(i)", isDeleted: i == 2))
        }
        sut.save()
        let result = sut.fetchAll()
        XCTAssertEqual(result.count, 4)
        XCTAssertFalse(result.contains(where: { $0.id == "addr-2" }))
    }

    func testFetchAll_sortsByCreatedAtDescending() {
        let older = makeAddress(id: "old", createdAt: Date().addingTimeInterval(-3600))
        let newer = makeAddress(id: "new", createdAt: Date())
        // Insert older first
        sut.insert(older)
        sut.insert(newer)
        sut.save()
        let result = sut.fetchAll()
        XCTAssertEqual(result.first?.id, "new",
                       "Newest address should be first (descending createdAt sort)")
    }

    func testFetchAll_afterDeletion_removedAddressNotReturned() {
        let addr = makeAddress(id: "to-delete")
        sut.insert(addr)
        sut.save()
        XCTAssertEqual(sut.fetchAll().count, 1)

        sut.delete(addr)
        sut.save()
        XCTAssertTrue(sut.fetchAll().isEmpty)
    }

    // MARK: - insert

    func testInsert_addsAddressToContext() {
        let addr = makeAddress(id: "ins-1")
        sut.insert(addr)
        sut.save()
        XCTAssertEqual(sut.fetchAll().count, 1)
    }

    func testInsert_multipleAddresses_allReturned() {
        for i in 0..<10 {
            sut.insert(makeAddress(id: "a-\(i)"))
        }
        sut.save()
        XCTAssertEqual(sut.fetchAll().count, 10)
    }

    func testInsert_preservesAllFields() {
        let date = Date(timeIntervalSinceReferenceDate: 1_000_000)
        let addr = makeAddress(
            id: "field-check",
            address: "hello@example.com",
            name: "Alice",
            isDeleted: false,
            isArchived: true,
            token: "tok-special",
            createdAt: date
        )
        sut.insert(addr)
        sut.save()

        let fetched = sut.fetchAll().first!
        XCTAssertEqual(fetched.id, "field-check")
        XCTAssertEqual(fetched.address, "hello@example.com")
        XCTAssertEqual(fetched.name, "Alice")
        XCTAssertTrue(fetched.isArchived)
        XCTAssertEqual(fetched.token, "tok-special")
        XCTAssertEqual(fetched.createdAt.timeIntervalSinceReferenceDate,
                       date.timeIntervalSinceReferenceDate,
                       accuracy: 1.0)
    }

    // MARK: - delete

    func testDelete_removesAddressFromStore() {
        let addr = makeAddress(id: "del-me")
        sut.insert(addr)
        sut.save()
        XCTAssertEqual(sut.fetchAll().count, 1)

        sut.delete(addr)
        sut.save()
        XCTAssertTrue(sut.fetchAll().isEmpty)
    }

    func testDelete_onlyRemovesTargetAddress() {
        let keep = makeAddress(id: "keep")
        let remove = makeAddress(id: "remove")
        sut.insert(keep)
        sut.insert(remove)
        sut.save()

        sut.delete(remove)
        sut.save()

        let remaining = sut.fetchAll()
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining.first?.id, "keep")
    }

    // MARK: - save

    func testSave_persistsInsertedAddressAcrossNewContext() throws {
        let addr = makeAddress(id: "persist-me")
        sut.insert(addr)
        sut.save()

        // Create a second repository backed by the same container
        let sut2 = AddressRepository(modelContext: container.mainContext)
        let result = sut2.fetchAll()
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, "persist-me")
    }

    // MARK: - archived addresses still returned by fetchAll

    func testFetchAll_includesArchivedAddresses() {
        let archived = makeAddress(id: "archived-1", isArchived: true)
        sut.insert(archived)
        sut.save()
        // fetchAll only excludes isDeleted, not isArchived
        XCTAssertEqual(sut.fetchAll().count, 1)
    }
}
