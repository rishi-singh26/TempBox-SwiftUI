//
//  AppStoreTests.swift
//  TempBoxTests
//

import XCTest
import SwiftUI
@testable import TempBox

final class AppStoreTests: XCTestCase {

    private let suiteName = "com.test.AppStoreTests"
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    @MainActor
    private func makeSUT() -> AppStore {
        AppStore(defaults: defaults)
    }

    // MARK: - Init defaults

    @MainActor
    func testInit_defaultWebViewAppearence_isSystem() {
        let sut = makeSUT()
        XCTAssertEqual(sut.webViewAppearence, WebViewColorScheme.system.rawValue)
    }

    @MainActor
    func testInit_webViewAppearence_restoredFromDefaults() {
        defaults.set(WebViewColorScheme.dark.rawValue, forKey: "webViewAppearence")
        let sut = makeSUT()
        XCTAssertEqual(sut.webViewAppearence, WebViewColorScheme.dark.rawValue)
    }

    @MainActor
    func testInit_selectedAccentColor_defaultsToFirst() {
        let sut = makeSUT()
        XCTAssertEqual(sut.selectedAccentColorData.id, AppStore.defaultAccentColors.first!.id)
    }

    @MainActor
    func testInit_showOnboarding_isFalseByDefault() {
        let sut = makeSUT()
        XCTAssertFalse(sut.showOnboarding)
    }

    // MARK: - webViewAppearence persistence

    @MainActor
    func testWebViewAppearence_didSet_persistsToDefaults() {
        let sut = makeSUT()
        sut.webViewAppearence = WebViewColorScheme.light.rawValue
        XCTAssertEqual(defaults.string(forKey: "webViewAppearence"), WebViewColorScheme.light.rawValue)
    }

    @MainActor
    func testWebViewColorScheme_computedFromString() {
        let sut = makeSUT()
        sut.webViewAppearence = WebViewColorScheme.dark.rawValue
        XCTAssertEqual(sut.webViewColorScheme, .dark)
    }

    @MainActor
    func testWebViewColorScheme_invalidString_fallsBackToSystem() {
        let sut = makeSUT()
        sut.webViewAppearence = "invalid"
        XCTAssertEqual(sut.webViewColorScheme, .system)
    }

    // MARK: - webViewColorScheme all cases

    @MainActor
    func testWebViewColorScheme_allCases() {
        let sut = makeSUT()
        for scheme in WebViewColorScheme.allCases {
            sut.webViewAppearence = scheme.rawValue
            XCTAssertEqual(sut.webViewColorScheme, scheme, "Expected \(scheme) for rawValue \(scheme.rawValue)")
        }
    }

    // MARK: - accentColor

    @MainActor
    func testAccentColor_lightScheme_returnsLightColor() {
        let sut = makeSUT()
        let color = sut.accentColor(colorScheme: .light)
        XCTAssertEqual(color, sut.selectedAccentColorData.light)
    }

    @MainActor
    func testAccentColor_darkScheme_returnsDarkColor() {
        let sut = makeSUT()
        let color = sut.accentColor(colorScheme: .dark)
        XCTAssertEqual(color, sut.selectedAccentColorData.dark)
    }

    // MARK: - addCustomColor / deleteCustomColor

    @MainActor
    func testAddCustomColor_appendsToArray() {
        let sut = makeSUT()
        let newColor = AccentColorData(id: "test-color", name: "Test Blue",
                                       light: Color(hex: "#0000FF"),
                                       dark: Color(hex: "#3333FF"))
        sut.addCustomColor(newColor)
        XCTAssertTrue(sut.customColors.contains(newColor))
    }

//    @MainActor
//    func testAddCustomColor_duplicate_notAddedTwice() {
//        let sut = makeSUT()
//        let color = AccentColorData(id: "dup-color", name: "Dup",
//                                    light: Color(hex: "#FF0000"),
//                                    dark: Color(hex: "#FF3333"))
//        sut.addCustomColor(color)
//        sut.addCustomColor(color)
//        let matches = sut.customColors.filter { $0.id == "dup-color" }
//        XCTAssertEqual(matches.count, 1)
//    }

    @MainActor
    func testDeleteCustomColor_removesById() {
        let sut = makeSUT()
        let color = AccentColorData(id: "del-color", name: "Del",
                                    light: Color(hex: "#00FF00"),
                                    dark: Color(hex: "#33FF33"))
        sut.addCustomColor(color)
        XCTAssertTrue(sut.customColors.contains(color))
        sut.deleteCustomColor(colorData: color)
        XCTAssertFalse(sut.customColors.contains(color))
    }

    @MainActor
    func testDeleteCustomColor_nonExistent_noChange() {
        let sut = makeSUT()
        let ghost = AccentColorData(id: "ghost", name: "Ghost",
                                    light: Color(hex: "#FFFFFF"),
                                    dark: Color(hex: "#000000"))
        let countBefore = sut.customColors.count
        sut.deleteCustomColor(colorData: ghost)
        XCTAssertEqual(sut.customColors.count, countBefore)
    }

    // MARK: - Onboarding

    @MainActor
    func testPrfomrOnbordingCheck_seenOnBoardingFalse_setsShowOnboardingTrue() async {
        defaults.set(false, forKey: "seenOnBoardingView")
        let sut = makeSUT()
        await sut.prfomrOnbordingCheck()
        XCTAssertTrue(sut.showOnboarding)
    }

    @MainActor
    func testPrfomrOnbordingCheck_seenOnBoardingTrue_doesNotShowOnboarding() async {
        defaults.set(true, forKey: "seenOnBoardingView")
        let sut = makeSUT()
        await sut.prfomrOnbordingCheck()
        XCTAssertFalse(sut.showOnboarding)
    }

    @MainActor
    func testHideOnboardingSheet_setsSeenInDefaultsAndHidesSheet() {
        defaults.set(false, forKey: "seenOnBoardingView")
        let sut = makeSUT()
        sut.showOnboarding = true
        sut.hideOnboardingSheet()
        XCTAssertFalse(sut.showOnboarding)
        XCTAssertTrue(defaults.bool(forKey: "seenOnBoardingView"),
                      "seenOnBoardingView should be persisted to defaults")
    }
    
    // MARK: - Disclaimer

    @MainActor
    func testPrfomrDisclaimerCheck_seenDisclaimerFalse_setsShowDisclaimerTrue() async {
        defaults.set(false, forKey: "seenDisclaimerView")
        let sut = makeSUT()
        await sut.performDisclaimerCheck()
        XCTAssertTrue(sut.showDisclaimer)
    }

    @MainActor
    func testPrfomrDisclaimerCheck_seenDisclaimerFalse_doesNotShowDisclaimer() async {
        defaults.set(true, forKey: "seenDisclaimerView")
        let sut = makeSUT()
        await sut.performDisclaimerCheck()
        XCTAssertFalse(sut.showDisclaimer)
    }

    @MainActor
    func testHideDisclaimerSheet_setsSeenInDefaultsAndHidesSheet() {
        defaults.set(false, forKey: "seenDisclaimerView")
        let sut = makeSUT()
        sut.showDisclaimer = true
        sut.hideDisclaimerSheet()
        XCTAssertFalse(sut.showDisclaimer)
        XCTAssertTrue(defaults.bool(forKey: "seenDisclaimerView"),
                      "seenDisclaimerView should be persisted to defaults")
    }

    @MainActor
    func testHideOnboardingSheet_subsequentCheck_doesNotShowOnboarding() async {
        let sut = makeSUT()
        sut.hideOnboardingSheet()
        // Create a second store reading the same defaults
        let sut2 = AppStore(defaults: defaults)
        await sut2.prfomrOnbordingCheck()
        XCTAssertFalse(sut2.showOnboarding)
    }

    // MARK: - selectedAccentColorData persistence

    @MainActor
    func testSelectedAccentColorData_persistedAndRestoredAcrossInstances() {
        let sut1 = makeSUT()
        let newColor = AppStore.defaultAccentColors[1]
        sut1.selectedAccentColorData = newColor

        let sut2 = AppStore(defaults: defaults)
        XCTAssertEqual(sut2.selectedAccentColorData.id, newColor.id)
    }

    // MARK: - WebViewColorScheme enum

    func testWebViewColorScheme_displayName_isCapitalized() {
        for scheme in WebViewColorScheme.allCases {
            XCTAssertEqual(scheme.displayName, scheme.rawValue.capitalized)
        }
    }

    func testWebViewColorScheme_allCasesCount() {
        XCTAssertEqual(WebViewColorScheme.allCases.count, 3)
    }

    // MARK: - Static constants

    func testDefaultAccentColors_notEmpty() {
        XCTAssertFalse(AppStore.defaultAccentColors.isEmpty)
    }

    func testAppId_notEmpty() {
        XCTAssertFalse(AppStore.appId.isEmpty)
    }

    func testAppAccentColorHex_validFormat() {
        XCTAssertTrue(AppStore.appAccentColorHex.hasPrefix("#"))
    }
}
