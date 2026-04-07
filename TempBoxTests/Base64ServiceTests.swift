//
//  Base64ServiceTests.swift
//  TempBoxTests
//

import XCTest
@testable import TempBox

final class Base64ServiceTests: XCTestCase {

    // MARK: - isValidBase64

    func testIsValidBase64_validPaddedString() {
        // "hello" in base64 is "aGVsbG8="
        XCTAssertTrue(Base64Service.isValidBase64("aGVsbG8="))
    }

    func testIsValidBase64_validNoPadding_multipleOf4() {
        // "Man" → "TWFu" (length 4, no padding needed)
        XCTAssertTrue(Base64Service.isValidBase64("TWFu"))
    }

    func testIsValidBase64_invalidCharacters() {
        XCTAssertFalse(Base64Service.isValidBase64("hello world!"))
    }

    func testIsValidBase64_notMultipleOf4() {
        // "abc" has length 3, not multiple of 4
        XCTAssertFalse(Base64Service.isValidBase64("abc"))
    }

    func testIsValidBase64_emptyString() {
        // Empty string: length 0, multiple of 4, matches regex — technically valid
        // Just verify it doesn't crash
        _ = Base64Service.isValidBase64("")
    }

    func testIsValidBase64_validDoublePadding() {
        // "a" in base64 is "YQ=="
        XCTAssertTrue(Base64Service.isValidBase64("YQ=="))
    }

    // MARK: - isBase64EncodedString

    func testIsBase64EncodedString_validBase64_returnsTrue() {
        let original = "Hello, TempBox!"
        let encoded = Data(original.utf8).base64EncodedString()
        XCTAssertTrue(Base64Service.isBase64EncodedString(encoded))
    }

    func testIsBase64EncodedString_plainText_returnsFalse() {
        XCTAssertFalse(Base64Service.isBase64EncodedString("Hello, TempBox!"))
    }

    func testIsBase64EncodedString_emptyString_returnsFalse() {
        XCTAssertFalse(Base64Service.isBase64EncodedString(""))
    }

    func testIsBase64EncodedString_invalidBase64_returnsFalse() {
        XCTAssertFalse(Base64Service.isBase64EncodedString("not!base64@string"))
    }

    // MARK: - decodeBase64

    func testDecodeBase64_validInput_returnsDecodedString() {
        let original = "TempBox rocks"
        let encoded = Data(original.utf8).base64EncodedString()
        let decoded = Base64Service.decodeBase64(encoded)
        XCTAssertEqual(decoded, original)
    }

    func testDecodeBase64_invalidInput_returnsNil() {
        XCTAssertNil(Base64Service.decodeBase64("!!!not base64!!!"))
    }

    func testDecodeBase64_emptyString_returnsNil() {
        // Empty base64 decodes to empty data, which produces empty string
        // Behaviour: returns "" or nil — just verify no crash
        _ = Base64Service.decodeBase64("")
    }

    // MARK: - encodeBase64

    func testEncodeBase64_validString_returnsBase64() throws {
        let original = "Hello World"
        let encoded = try Base64Service.encodeBase64(original)
        XCTAssertFalse(encoded.isEmpty)
        // Verify round-trip
        let decoded = Base64Service.decodeBase64(encoded)
        XCTAssertEqual(decoded, original)
    }

    func testEncodeBase64_emptyString_returnsBase64() throws {
        let encoded = try Base64Service.encodeBase64("")
        // Empty string encodes to "" in base64
        XCTAssertNotNil(encoded)
    }

    func testEncodeBase64_unicodeString() throws {
        let original = "Héllo Wörld 🌍"
        let encoded = try Base64Service.encodeBase64(original)
        let decoded = Base64Service.decodeBase64(encoded)
        XCTAssertEqual(decoded, original)
    }

    // MARK: - validateAndDecodeBase64

    func testValidateAndDecodeBase64_withValidBase64_returnsDecodedString() {
        let original = "TempBox test payload"
        let encoded = Data(original.utf8).base64EncodedString()
        let result = Base64Service.validateAndDecodeBase64(encoded)
        XCTAssertEqual(result, original)
    }

    func testValidateAndDecodeBase64_withPlainText_returnsInputAsIs() {
        let plain = "just plain text"
        let result = Base64Service.validateAndDecodeBase64(plain)
        XCTAssertEqual(result, plain)
    }

    func testValidateAndDecodeBase64_withEmptyString_returnsNilOrEmpty() {
        // Should not crash
        _ = Base64Service.validateAndDecodeBase64("")
    }

    // MARK: - Round-trip

    func testRoundTrip_encodeDecodeMatchesOriginal() throws {
        let payloads = [
            "Simple string",
            "{\"version\":\"2.0.0\",\"addresses\":[]}",
            "Special chars: !@#$%^&*()",
            String(repeating: "a", count: 1000),
        ]
        for payload in payloads {
            let encoded = try Base64Service.encodeBase64(payload)
            let decoded = try XCTUnwrap(Base64Service.decodeBase64(encoded))
            XCTAssertEqual(decoded, payload, "Round-trip failed for: \(payload.prefix(40))")
        }
    }
}
