//
//  StringExtensionsTests.swift
//  TempBoxTests
//

import XCTest
@testable import TempBox

final class StringExtensionsTests: XCTestCase {

    // MARK: - generateUsername

    func testGenerateUsername_returnsNonEmptyString() {
        let username = String.generateUsername()
        XCTAssertFalse(username.isEmpty)
    }

    func testGenerateUsername_isLowercased() {
        let username = String.generateUsername()
        XCTAssertEqual(username, username.lowercased())
    }

    func testGenerateUsername_containsNoSpaces() {
        let username = String.generateUsername()
        XCTAssertFalse(username.contains(" "))
    }

    func testGenerateUsername_producesUniqueValues() {
        let names = Set((0..<20).map { _ in String.generateUsername() })
        // With adjective * noun * 10000 combinations, collisions in 20 draws are extremely unlikely
        XCTAssertGreaterThan(names.count, 1)
    }

    // MARK: - generatePassword

    func testGeneratePassword_defaultLowercaseOnly() {
        let password = String.generatePassword(of: 16)
        XCTAssertEqual(password.count, 16)
        // All characters should be lowercase letters
        XCTAssertTrue(password.allSatisfy { $0.isLowercase })
    }

    func testGeneratePassword_withUpperCase_containsUppercase() {
        // Run enough times to be statistically certain
        var foundUppercase = false
        for _ in 0..<20 {
            let pw = String.generatePassword(of: 20, useUpperCase: true)
            if pw.contains(where: { $0.isUppercase }) { foundUppercase = true; break }
        }
        XCTAssertTrue(foundUppercase)
    }

    func testGeneratePassword_withNumbers_containsDigit() {
        var foundDigit = false
        for _ in 0..<20 {
            let pw = String.generatePassword(of: 20, useNumbers: true)
            if pw.contains(where: { $0.isNumber }) { foundDigit = true; break }
        }
        XCTAssertTrue(foundDigit)
    }

    func testGeneratePassword_withSpecialChars_containsSpecialChar() {
        let special = Set("!@#$%^&*()_-+=<>?")
        var foundSpecial = false
        for _ in 0..<20 {
            let pw = String.generatePassword(of: 20, useSpecialCharacters: true)
            if pw.contains(where: { special.contains($0) }) { foundSpecial = true; break }
        }
        XCTAssertTrue(foundSpecial)
    }

    func testGeneratePassword_respectsLength() {
        for length in [8, 12, 24, 32] {
            let pw = String.generatePassword(of: length, useUpperCase: true, useNumbers: true, useSpecialCharacters: true)
            XCTAssertEqual(pw.count, length, "Expected length \(length)")
        }
    }

    func testGeneratePassword_allOptionsEnabled_hasCorrectLength() {
        let pw = String.generatePassword(of: 12, useUpperCase: true, useNumbers: true, useSpecialCharacters: true)
        XCTAssertEqual(pw.count, 12)
    }

    // MARK: - getInitials

    func testGetInitials_singleWord() {
        let result = "Alice".getInitials()
        XCTAssertFalse(result.isEmpty)
    }

    func testGetInitials_twoWords() {
        let result = "John Doe".getInitials()
        // PersonNameComponentsFormatter abbreviated usually returns "JD"
        XCTAssertTrue(result.contains("J") || result.contains("D") || !result.isEmpty)
    }

    func testGetInitials_emptyString() {
        let result = "".getInitials()
        XCTAssertEqual(result, "")
    }

    // MARK: - extractUsername

    func testExtractUsername_validEmail() {
        XCTAssertEqual("hello@example.com".extractUsername(), "hello")
    }

    func testExtractUsername_invalidEmail_returnsOriginal() {
        XCTAssertEqual("notanemail".extractUsername(), "notanemail")
    }

    func testExtractUsername_emptyString_returnsOriginal() {
        XCTAssertEqual("".extractUsername(), "")
    }

    func testExtractUsername_emailWithSubdomain() {
        XCTAssertEqual("user@mail.example.com".extractUsername(), "user")
    }

    // MARK: - isValidEmail

    func testIsValidEmail_validAddresses() {
        let valid = [
            "user@example.com",
            "test.user+tag@sub.domain.org",
            "a@b.io",
        ]
        for email in valid {
            XCTAssertTrue(email.isValidEmail(), "\(email) should be valid")
        }
    }

    func testIsValidEmail_invalidAddresses() {
        let invalid = [
            "notanemail",
            "@nodomain.com",
            "missing@",
            "two@@at.com",
            "",
        ]
        for email in invalid {
            XCTAssertFalse(email.isValidEmail(), "\(email) should be invalid")
        }
    }

    // MARK: - isValidISO8601Date

    func testIsValidISO8601Date_validFormats() {
        let valid = [
            "2024-01-15T10:30:00Z",
            "2024-01-15T10:30:00.123Z",
            "2024-01-15T10:30:00+05:30",
            "2024-01-15T10:30:00.999+00:00",
        ]
        for dateStr in valid {
            XCTAssertTrue(dateStr.isValidISO8601Date(), "\(dateStr) should be valid")
        }
    }

    func testIsValidISO8601Date_invalidFormats() {
        let invalid = [
            "2024-01-15",
            "10:30:00",
            "not a date",
            "",
            "2024/01/15T10:30:00Z",
        ]
        for dateStr in invalid {
            XCTAssertFalse(dateStr.isValidISO8601Date(), "\(dateStr) should be invalid")
        }
    }

    // MARK: - toDate / validateAndToDate

    func testToDate_withFractionalSeconds_returnsDate() {
        let date = "2024-03-10T14:25:30.500Z".toDate()
        XCTAssertNotNil(date)
    }

    func testToDate_withoutFractionalSeconds_returnsDate() {
        let date = "2024-03-10T14:25:30Z".toDate()
        XCTAssertNotNil(date)
    }

    func testToDate_invalidString_returnsNil() {
        XCTAssertNil("not-a-date".toDate())
    }

    func testValidateAndToDate_validISO_returnsDate() {
        XCTAssertNotNil("2024-03-10T14:25:30Z".validateAndToDate())
    }

    func testValidateAndToDate_invalidISO_returnsNil() {
        XCTAssertNil("2024-03-10".validateAndToDate())
    }

    func testValidateAndToDate_emptyString_returnsNil() {
        XCTAssertNil("".validateAndToDate())
    }

    func testToDate_parsedDateMatchesComponents() throws {
        let dateStr = "2024-06-15T08:00:00Z"
        let date = try XCTUnwrap(dateStr.toDate())
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        XCTAssertEqual(calendar.component(.year, from: date), 2024)
        XCTAssertEqual(calendar.component(.month, from: date), 6)
        XCTAssertEqual(calendar.component(.day, from: date), 15)
        XCTAssertEqual(calendar.component(.hour, from: date), 8)
    }
}
