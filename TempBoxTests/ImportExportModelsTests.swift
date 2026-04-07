//
//  ImportExportModelsTests.swift
//  TempBoxTests
//

import XCTest
@testable import TempBox

final class ImportExportModelsTests: XCTestCase {

    // MARK: - Fixtures

    private func makeV2Address(
        name: String? = "Test User",
        id: String = "addr-001",
        email: String = "test@example.com",
        password: String = "secret123",
        archived: String = "No",
        createdAt: String = "2024-03-10T08:00:00Z"
    ) -> ExportVersionTwoAddress {
        ExportVersionTwoAddress(
            addressName: name,
            id: id,
            email: email,
            password: password,
            archived: archived,
            createdAt: createdAt
        )
    }

    private var validV1JSON: Data {
        let json = """
        {
            "version": "1.0.0",
            "exportDate": "2024-01-15T10:00:00Z",
            "addresses": [
                {
                    "addressName": "Work",
                    "password": "pass1234",
                    "authenticatedUser": {
                        "account": {
                            "id": "acct-001",
                            "address": "work@example.com",
                            "quota": 40000000,
                            "used": 0,
                            "isDisabled": false,
                            "isDeleted": false,
                            "createdAt": "2024-01-01T00:00:00+00:00",
                            "updatedAt": "2024-01-01T00:00:00+00:00"
                        },
                        "password": "pass1234",
                        "token": "tok_abc123"
                    }
                }
            ]
        }
        """
        return json.data(using: .utf8)!
    }

    private var validV2JSON: Data {
        let json = """
        {
            "version": "2.0.0",
            "exportDate": "2024-03-10T08:00:00Z",
            "addresses": [
                {
                    "addressName": "Personal",
                    "id": "addr-002",
                    "email": "personal@example.com",
                    "password": "securePass!1",
                    "archived": "No",
                    "createdAt": "2024-02-01T00:00:00Z"
                }
            ]
        }
        """
        return json.data(using: .utf8)!
    }

    // MARK: - ExportVersionTwoAddress computed properties

    func testIfNameElseAddress_withName_returnsName() {
        let addr = makeV2Address(name: "Alice")
        XCTAssertEqual(addr.ifNameElseAddress, "Alice")
    }

    func testIfNameElseAddress_nilName_returnsEmail() {
        let addr = makeV2Address(name: nil)
        XCTAssertEqual(addr.ifNameElseAddress, "test@example.com")
    }

    func testIfNameElseAddress_emptyName_returnsEmail() {
        let addr = makeV2Address(name: "")
        XCTAssertEqual(addr.ifNameElseAddress, "test@example.com")
    }

    func testIfNameThenAddress_withName_returnsEmail() {
        let addr = makeV2Address(name: "Alice")
        XCTAssertEqual(addr.ifNameThenAddress, "test@example.com")
    }

    func testIfNameThenAddress_nilName_returnsEmpty() {
        let addr = makeV2Address(name: nil)
        XCTAssertEqual(addr.ifNameThenAddress, "")
    }

    func testIfNameThenAddress_emptyName_returnsEmpty() {
        let addr = makeV2Address(name: "")
        XCTAssertEqual(addr.ifNameThenAddress, "")
    }

    func testCreatedAtDate_validISO_returnsDate() {
        let addr = makeV2Address(createdAt: "2024-03-10T08:00:00Z")
        // validateAndToDate should succeed for a valid ISO8601 string
        let expectedDate = "2024-03-10T08:00:00Z".toDate()
        XCTAssertNotNil(addr.createdAtDate)
        if let expected = expectedDate {
            XCTAssertEqual(addr.createdAtDate.timeIntervalSince1970,
                           expected.timeIntervalSince1970,
                           accuracy: 1.0)
        }
    }

//    func testCreatedAtDate_invalidISO_fallsBackToNow() {
//        let before = Date()
//        let addr = makeV2Address(createdAt: "not-a-date")
//        // When validation fails, createdAtDate falls back to Date.now
//        
//        XCTAssertGreaterThanOrEqual(addr.createdAtDate, before)
//        let after = Date()
//        XCTAssertLessThanOrEqual(addr.createdAtDate, after)
//    }

    // MARK: - ExportVersionTwo init

    func testExportVersionTwo_init_setsVersion() {
        let export = ExportVersionTwo(addresses: [])
        XCTAssertEqual(export.version, "2.0.0")
    }

    func testExportVersionTwo_init_setsExportDate() {
        let before = Date()
        let export = ExportVersionTwo(addresses: [])
        let after = Date()
        // exportDate is an ISO8601 string set to Date.now inside init
        let parsed = export.exportDate.toDate()
        XCTAssertNotNil(parsed)
        if let parsed = parsed {
            XCTAssertGreaterThanOrEqual(parsed, before.addingTimeInterval(-1))
            XCTAssertLessThanOrEqual(parsed, after.addingTimeInterval(1))
        }
    }

    func testExportVersionTwo_init_setsAddresses() {
        let addresses = [makeV2Address(), makeV2Address(id: "addr-002", email: "b@example.com")]
        let export = ExportVersionTwo(addresses: addresses)
        XCTAssertEqual(export.addresses.count, 2)
    }

    // MARK: - ExportVersionTwo toJSON (String)

    func testExportVersionTwo_toJSONString_containsVersion() throws {
        let export = ExportVersionTwo(addresses: [makeV2Address()])
        let json = try export.toJSON() as String
        XCTAssertTrue(json.contains("2.0.0"))
    }

    func testExportVersionTwo_toJSONString_containsEmailAddress() throws {
        let export = ExportVersionTwo(addresses: [makeV2Address(email: "unique@test.io")])
        let json = try export.toJSON() as String
        XCTAssertTrue(json.contains("unique@test.io"))
    }

    func testExportVersionTwo_toJSONString_prettyPrinted_hasNewlines() throws {
        let export = ExportVersionTwo(addresses: [makeV2Address()])
        let json = try export.toJSON(prettyPrinted: true) as String
        XCTAssertTrue(json.contains("\n"))
    }

    func testExportVersionTwo_toJSONString_notPrettyPrinted_noNewlines() throws {
        let export = ExportVersionTwo(addresses: [makeV2Address()])
        let json = try export.toJSON(prettyPrinted: false) as String
        XCTAssertFalse(json.contains("\n"))
    }

    // MARK: - ExportVersionTwo toJSON (Data)

    func testExportVersionTwo_toJSONData_isDecodable() throws {
        let original = ExportVersionTwo(addresses: [makeV2Address()])
        let data = try original.toJSON() as Data
        let decoded = try JSONDecoder().decode(ExportVersionTwo.self, from: data)
        XCTAssertEqual(decoded.addresses.count, 1)
        XCTAssertEqual(decoded.addresses.first?.email, "test@example.com")
    }

    // MARK: - ExportVersionTwo decoding — version mismatch

    func testExportVersionTwo_versionMismatch_throwsDecodingError() {
        let wrongVersionJSON = """
        {"version":"1.0.0","exportDate":"2024-01-01T00:00:00Z","addresses":[]}
        """.data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(ExportVersionTwo.self, from: wrongVersionJSON)) { error in
            XCTAssertTrue(error is DecodingError, "Expected DecodingError, got \(type(of: error))")
        }
    }

    func testExportVersionTwo_missingField_throwsDecodingError() {
        let badJSON = """
        {"version":"2.0.0","addresses":[]}
        """.data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(ExportVersionTwo.self, from: badJSON))
    }

    // MARK: - ExportVersionTwo toCSV

    func testToCSV_containsHeader() {
        let export = ExportVersionTwo(addresses: [makeV2Address()])
        let csv = export.toCSV()
        XCTAssertTrue(csv.hasPrefix("Address Name,Email,Password,Archived,Created At,ID"))
    }

    func testToCSV_containsEmailAddress() {
        let export = ExportVersionTwo(addresses: [makeV2Address(email: "csv@example.com")])
        let csv = export.toCSV()
        XCTAssertTrue(csv.contains("csv@example.com"))
    }

    func testToCSV_emptyAddresses_onlyHeader() {
        let export = ExportVersionTwo(addresses: [])
        let csv = export.toCSV()
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }
        XCTAssertEqual(lines.count, 1, "Only the header row should exist")
    }

    func testToCSV_multipleAddresses_correctRowCount() {
        let addresses = (0..<3).map { i in
            makeV2Address(id: "id-\(i)", email: "user\(i)@example.com")
        }
        let export = ExportVersionTwo(addresses: addresses)
        let csv = export.toCSV()
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }
        XCTAssertEqual(lines.count, 4, "Header + 3 data rows")
    }

    func testToCSV_quoteEscaping_handlesCommasInName() {
        let addr = makeV2Address(name: "Doe, Jane")
        let export = ExportVersionTwo(addresses: [addr])
        let csv = export.toCSV()
        // The name with a comma should be wrapped in quotes
        XCTAssertTrue(csv.contains("\"Doe, Jane\""))
    }

    func testToCSV_quotesInName_areEscaped() {
        let addr = makeV2Address(name: "He said \"hi\"")
        let export = ExportVersionTwo(addresses: [addr])
        let csv = export.toCSV()
        // Double-quote escaping: " → ""
        XCTAssertTrue(csv.contains("\"\""))
    }

    // MARK: - ExportVersionOne decoding

    func testExportVersionOne_decode_succeeds() throws {
        let decoded = try JSONDecoder().decode(ExportVersionOne.self, from: validV1JSON)
        XCTAssertEqual(decoded.version, "1.0.0")
        XCTAssertEqual(decoded.addresses.count, 1)
    }

    func testExportVersionOne_decode_addressFields() throws {
        let decoded = try JSONDecoder().decode(ExportVersionOne.self, from: validV1JSON)
        let addr = try XCTUnwrap(decoded.addresses.first)
        XCTAssertEqual(addr.addressName, "Work")
        XCTAssertEqual(addr.authenticatedUser.account.address, "work@example.com")
        XCTAssertEqual(addr.authenticatedUser.token, "tok_abc123")
    }

    func testExportVersionOne_versionMismatch_throwsDecodingError() {
        let wrongVersion = """
        {"version":"2.0.0","exportDate":"2024-01-01T00:00:00Z","addresses":[]}
        """.data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(ExportVersionOne.self, from: wrongVersion))
    }

    func testExportVersionOne_toJSON_containsVersion() throws {
        let decoded = try JSONDecoder().decode(ExportVersionOne.self, from: validV1JSON)
        let json = try decoded.toJSON()
        XCTAssertTrue(json.contains("1.0.0"))
    }

    func testExportVersionOne_toJSON_roundTrip() throws {
        let original = try JSONDecoder().decode(ExportVersionOne.self, from: validV1JSON)
        let jsonString = try original.toJSON()
        let jsonData = try XCTUnwrap(jsonString.data(using: .utf8))
        let restored = try JSONDecoder().decode(ExportVersionOne.self, from: jsonData)
        XCTAssertEqual(restored.addresses.count, original.addresses.count)
        XCTAssertEqual(restored.addresses.first?.addressName, original.addresses.first?.addressName)
    }

    // MARK: - ExportVersionTwo full round-trip

    func testExportVersionTwo_roundTrip_preservesAllFields() throws {
        let address = makeV2Address(
            name: "Round Trip",
            id: "rt-001",
            email: "rt@example.com",
            password: "rtPass!99",
            archived: "Yes",
            createdAt: "2024-05-01T12:00:00Z"
        )
        let original = ExportVersionTwo(addresses: [address])
        let data = try original.toJSON() as Data
        let restored = try JSONDecoder().decode(ExportVersionTwo.self, from: data)

        XCTAssertEqual(restored.version, "2.0.0")
        XCTAssertEqual(restored.addresses.count, 1)
        let restoredAddr = try XCTUnwrap(restored.addresses.first)
        XCTAssertEqual(restoredAddr.id, "rt-001")
        XCTAssertEqual(restoredAddr.email, "rt@example.com")
        XCTAssertEqual(restoredAddr.password, "rtPass!99")
        XCTAssertEqual(restoredAddr.archived, "Yes")
        XCTAssertEqual(restoredAddr.addressName, "Round Trip")
    }
}
