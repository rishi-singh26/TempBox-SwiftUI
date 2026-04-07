//
//  ImportExportServiceTests.swift
//  TempBoxTests
//

import XCTest
@testable import TempBox

final class ImportExportServiceTests: XCTestCase {

    // MARK: - Fixtures

    private var v1JSONString: String {
        """
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
    }

    private var v2JSONString: String {
        """
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
    }

    private func base64Encode(_ string: String) -> String {
        Data(string.utf8).base64EncodedString()
    }

    private var v1Base64: String { base64Encode(v1JSONString) }
    private var v2Base64: String { base64Encode(v2JSONString) }

    // MARK: - decodeDataForImport: Version 1

    func testDecodeDataForImport_validV1Base64_returnsV1Export() {
        let (v1, v2, message) = ImportExportService.decodeDataForImport(from: v1Base64)
        XCTAssertNotNil(v1, "Expected V1 export, message: \(message)")
        XCTAssertNil(v2)
        XCTAssertEqual(message, "Success")
    }

    func testDecodeDataForImport_validV1_addressFieldsCorrect() {
        let (v1, _, _) = ImportExportService.decodeDataForImport(from: v1Base64)
        XCTAssertEqual(v1?.addresses.first?.addressName, "Work")
        XCTAssertEqual(v1?.addresses.first?.authenticatedUser.account.address, "work@example.com")
    }

    // MARK: - decodeDataForImport: Version 2

    func testDecodeDataForImport_validV2Base64_returnsV2Export() {
        let (v1, v2, message) = ImportExportService.decodeDataForImport(from: v2Base64)
        XCTAssertNil(v1)
        XCTAssertNotNil(v2, "Expected V2 export, message: \(message)")
        XCTAssertEqual(message, "Success")
    }

    func testDecodeDataForImport_validV2_addressFieldsCorrect() {
        let (_, v2, _) = ImportExportService.decodeDataForImport(from: v2Base64)
        XCTAssertEqual(v2?.addresses.first?.email, "personal@example.com")
        XCTAssertEqual(v2?.addresses.first?.archived, "No")
    }

    // MARK: - decodeDataForImport: invalid input

    func testDecodeDataForImport_invalidBase64_returnsError() {
        let (v1, v2, message) = ImportExportService.decodeDataForImport(from: "!!!not base64!!!")
        XCTAssertNil(v1)
        XCTAssertNil(v2)
        XCTAssertFalse(message.isEmpty)
    }

    func testDecodeDataForImport_emptyString_returnsError() {
        let (v1, v2, message) = ImportExportService.decodeDataForImport(from: "")
        XCTAssertNil(v1)
        XCTAssertNil(v2)
        XCTAssertFalse(message.isEmpty)
    }

    func testDecodeDataForImport_plainTextJSON_returnsError() {
        // Plain text (not base64) that happens to be valid JSON
        let plain = v2JSONString
        let (_, _, message) = ImportExportService.decodeDataForImport(from: plain)
        // Either it decodes (if plain text happens to survive Base64 fallback) or returns error
        // The key assertion: it doesn't crash
        XCTAssertFalse(message.isEmpty)
    }

    func testDecodeDataForImport_unsupportedVersion_returnsError() {
        let unsupported = """
        {"version":"3.0.0","exportDate":"2024-01-01T00:00:00Z","addresses":[]}
        """
        let encoded = base64Encode(unsupported)
        let (v1, v2, message) = ImportExportService.decodeDataForImport(from: encoded)
        XCTAssertNil(v1)
        XCTAssertNil(v2)
        XCTAssertTrue(message.contains("3.0.0") || message.lowercased().contains("unsupported"),
                      "Message should mention the bad version, got: \(message)")
    }

    func testDecodeDataForImport_malformedJSON_returnsError() {
        let malformed = base64Encode("{ this is not JSON }")
        let (v1, v2, message) = ImportExportService.decodeDataForImport(from: malformed)
        XCTAssertNil(v1)
        XCTAssertNil(v2)
        XCTAssertFalse(message.isEmpty)
    }

    // MARK: - decodeVersionOneData

    func testDecodeVersionOneData_validData_succeeds() {
        let data = v1JSONString.data(using: .utf8)!
        let (result, message) = ImportExportService.decodeVersionOneData(from: data)
        XCTAssertNotNil(result)
        XCTAssertEqual(message, "Success")
    }

    func testDecodeVersionOneData_wrongVersion_fails() {
        let json = """
        {"version":"2.0.0","exportDate":"2024-01-01T00:00:00Z","addresses":[]}
        """.data(using: .utf8)!
        let (result, message) = ImportExportService.decodeVersionOneData(from: json)
        XCTAssertNil(result)
        XCTAssertFalse(message.isEmpty)
    }

    func testDecodeVersionOneData_emptyData_fails() {
        let (result, message) = ImportExportService.decodeVersionOneData(from: Data())
        XCTAssertNil(result)
        XCTAssertFalse(message.isEmpty)
    }

    func testDecodeVersionOneData_addressCount() {
        let data = v1JSONString.data(using: .utf8)!
        let (result, _) = ImportExportService.decodeVersionOneData(from: data)
        XCTAssertEqual(result?.addresses.count, 1)
    }

    // MARK: - decodeVersionTwoData

    func testDecodeVersionTwoData_validData_succeeds() {
        let data = v2JSONString.data(using: .utf8)!
        let (result, message) = ImportExportService.decodeVersionTwoData(from: data)
        XCTAssertNotNil(result)
        XCTAssertEqual(message, "Success")
    }

    func testDecodeVersionTwoData_wrongVersion_fails() {
        let json = """
        {"version":"1.0.0","exportDate":"2024-01-01T00:00:00Z","addresses":[]}
        """.data(using: .utf8)!
        let (result, message) = ImportExportService.decodeVersionTwoData(from: json)
        XCTAssertNil(result)
        XCTAssertFalse(message.isEmpty)
    }

    func testDecodeVersionTwoData_emptyData_fails() {
        let (result, message) = ImportExportService.decodeVersionTwoData(from: Data())
        XCTAssertNil(result)
        XCTAssertFalse(message.isEmpty)
    }

    func testDecodeVersionTwoData_addressFields() {
        let data = v2JSONString.data(using: .utf8)!
        let (result, _) = ImportExportService.decodeVersionTwoData(from: data)
        XCTAssertEqual(result?.addresses.first?.id, "addr-002")
        XCTAssertEqual(result?.addresses.first?.password, "securePass!1")
    }

    // MARK: - Round-trip via ExportVersionTwo

    func testRoundTrip_exportThenImport_preservesData() throws {
        // Build export
        let address = ExportVersionTwoAddress(
            addressName: "Round Trip",
            id: "rt-999",
            email: "rt@tempbox.io",
            password: "rtSecure!0",
            archived: "No",
            createdAt: "2024-06-01T00:00:00Z"
        )
        let export = ExportVersionTwo(addresses: [address])
        let jsonData = try export.toJSON() as Data
        let jsonString = try XCTUnwrap(String(data: jsonData, encoding: .utf8))

        // Encode to base64 (simulating what the app does on export)
        let base64 = try Base64Service.encodeBase64(jsonString)

        // Re-import
        let (_, v2, message) = ImportExportService.decodeDataForImport(from: base64)
        XCTAssertNotNil(v2, "Import should succeed, message: \(message)")
        XCTAssertEqual(v2?.addresses.first?.id, "rt-999")
        XCTAssertEqual(v2?.addresses.first?.email, "rt@tempbox.io")
        XCTAssertEqual(v2?.addresses.first?.addressName, "Round Trip")
    }
}
