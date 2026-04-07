//
//  DateExtensionsTests.swift
//  TempBoxTests
//

import XCTest
@testable import TempBox

final class DateExtensionsTests: XCTestCase {

    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        calendar = Calendar.current
    }

    // MARK: - formatRelativeString

    func testFormatRelativeString_today_noDatePrefix() {
        // A date that is clearly today
        let date = Date()
        let result = date.formatRelativeString()
        XCTAssertFalse(result.hasPrefix("Yesterday"), "Today's date should not have 'Yesterday' prefix")
        XCTAssertFalse(result.isEmpty)
    }

    func testFormatRelativeString_yesterday_prefixYesterday() {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        let result = yesterday.formatRelativeString()
        XCTAssertTrue(result.hasPrefix("Yesterday,"), "Yesterday should start with 'Yesterday,'")
    }

    func testFormatRelativeString_olderDate_containsMonthAbbreviation() {
        // 30 days ago is definitely neither today nor yesterday
        let older = calendar.date(byAdding: .day, value: -30, to: Date())!
        let result = older.formatRelativeString()
        let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        let containsMonth = months.contains(where: { result.contains($0) })
        XCTAssertTrue(containsMonth, "Older date should contain month abbreviation, got: \(result)")
    }

    func testFormatRelativeString_olderDate_containsDaySuffix() {
        let older = calendar.date(byAdding: .day, value: -30, to: Date())!
        let result = older.formatRelativeString()
        let suffixes = ["st", "nd", "rd", "th"]
        let containsSuffix = suffixes.contains(where: { result.contains($0) })
        XCTAssertTrue(containsSuffix, "Date should contain ordinal suffix, got: \(result)")
    }

    func testFormatRelativeString_differentYear_containsYear() {
        // Use a fixed date from a past year
        var components = DateComponents()
        components.year = 2020
        components.month = 5
        components.day = 10
        components.hour = 12
        components.minute = 0
        let pastDate = calendar.date(from: components)!
        let result = pastDate.formatRelativeString()
        XCTAssertTrue(result.contains("2020"), "Past year date should contain the year, got: \(result)")
    }

    func testFormatRelativeString_sameYear_doesNotContainYear() {
        // 10 days ago in the same year should NOT include the year
        let tenDaysAgo = calendar.date(byAdding: .day, value: -10, to: Date())!
        let currentYear = calendar.component(.year, from: Date())
        let result = tenDaysAgo.formatRelativeString()

        // Only assert year absence if 10 days ago is in the same year
        let yearOfDate = calendar.component(.year, from: tenDaysAgo)
        if yearOfDate == currentYear {
            XCTAssertFalse(result.contains(String(currentYear)),
                           "Same-year date should not contain year, got: \(result)")
        }
    }

    func testFormatRelativeString_dayOneSuffix() {
        // 1st, 21st, 31st → "st"
        var comps = DateComponents()
        comps.year = 2020
        comps.month = 3
        comps.day = 1
        comps.hour = 12
        let date = calendar.date(from: comps)!
        let result = date.formatRelativeString()
        XCTAssertTrue(result.contains("1st"), "Day 1 should have 'st' suffix, got: \(result)")
    }

    func testFormatRelativeString_dayTwoSuffix() {
        var comps = DateComponents()
        comps.year = 2020
        comps.month = 3
        comps.day = 2
        comps.hour = 12
        let date = calendar.date(from: comps)!
        let result = date.formatRelativeString()
        XCTAssertTrue(result.contains("2nd"), "Day 2 should have 'nd' suffix, got: \(result)")
    }

    func testFormatRelativeString_dayThreeSuffix() {
        var comps = DateComponents()
        comps.year = 2020
        comps.month = 3
        comps.day = 3
        comps.hour = 12
        let date = calendar.date(from: comps)!
        let result = date.formatRelativeString()
        XCTAssertTrue(result.contains("3rd"), "Day 3 should have 'rd' suffix, got: \(result)")
    }

    func testFormatRelativeString_dayElevenSuffix() {
        // 11, 12, 13 are exceptions — always "th"
        var comps = DateComponents()
        comps.year = 2020
        comps.month = 3
        comps.day = 11
        comps.hour = 12
        let date = calendar.date(from: comps)!
        let result = date.formatRelativeString()
        XCTAssertTrue(result.contains("11th"), "Day 11 should have 'th' suffix, got: \(result)")
    }

    func testFormatRelativeString_day12Suffix() {
        var comps = DateComponents()
        comps.year = 2020
        comps.month = 3
        comps.day = 12
        comps.hour = 12
        let date = calendar.date(from: comps)!
        let result = date.formatRelativeString()
        XCTAssertTrue(result.contains("12th"), "Day 12 should have 'th' suffix, got: \(result)")
    }

    func testFormatRelativeString_day21Suffix() {
        var comps = DateComponents()
        comps.year = 2020
        comps.month = 3
        comps.day = 21
        comps.hour = 12
        let date = calendar.date(from: comps)!
        let result = date.formatRelativeString()
        XCTAssertTrue(result.contains("21st"), "Day 21 should have 'st' suffix, got: \(result)")
    }

    // MARK: - dd_mmm_yyyy

    func testDdMmmYyyy_formatsCorrectly() {
        var comps = DateComponents()
        comps.year = 2024
        comps.month = 3
        comps.day = 5
        let date = calendar.date(from: comps)!
        let result = date.dd_mmm_yyyy()
        // Should contain "05", "Mar", and "2024" in some locale-dependent format
        XCTAssertTrue(result.contains("2024"), "Year should be present")
        XCTAssertFalse(result.isEmpty)
    }

    func testDdMmmYyyy_returnsNonEmptyString() {
        XCTAssertFalse(Date().dd_mmm_yyyy().isEmpty)
    }
}
