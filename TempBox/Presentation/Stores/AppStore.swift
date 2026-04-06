//
//  AppStore.swift
//  TempBox
//
//  Created by Rishi Singh on 06/04/26.
//

import SwiftUI
import StoreKit

@Observable
final class AppStore {
    // MARK: - Navigation (iPhone only)
    var path = NavigationPath()

    // MARK: - Theme
    var selectedAccentColorData: AccentColorData {
        didSet { self.saveAccentColorData(selectedAccentColorData) }
    }
    var customColors: [AccentColorData] = [] {
        didSet { saveCustomColorsToFile() }
    }

    // MARK: - WebView appearance (replaces @AppStorage("webViewAppearence"))
    var webViewAppearence: String {
        didSet { UserDefaults.standard.set(webViewAppearence, forKey: "webViewAppearence") }
    }
    var webViewColorScheme: WebViewColorScheme {
        WebViewColorScheme(rawValue: webViewAppearence) ?? .system
    }

    // MARK: - Onboarding (replaces @AppStorage("seenOnBoardingView"))
    private var seenOnBoardingView: Bool
    var showOnboarding: Bool = false

    // MARK: - Init

    init() {
        webViewAppearence = UserDefaults.standard.string(forKey: "webViewAppearence") ?? WebViewColorScheme.system.rawValue
        seenOnBoardingView = UserDefaults.standard.bool(forKey: "seenOnBoardingView")
        if let saved = Self.loadAccentColorData() {
            selectedAccentColorData = saved
        } else {
            selectedAccentColorData = AppStore.defaultAccentColors.first!
        }
        #if os(iOS)
        self.customColors = Self.loadCustomColorsFromFile()
        #endif
    }

    // MARK: - Color helpers

    func accentColor(colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark:
            return selectedAccentColorData.dark
        case .light:
            return selectedAccentColorData.light
        @unknown default:
            return Color(hex: AppStore.appAccentColorHex)
        }
    }

    func addCustomColor(_ color: AccentColorData) {
        guard !customColors.contains(color) else { return }
        customColors.append(color)
    }

    func deleteCustomColor(colorData: AccentColorData) {
        customColors.removeAll { $0.id == colorData.id }
    }

    // MARK: - Onboarding

    func prfomrOnbordingCheck() async {
        try? await Task.sleep(for: .seconds(0.2))
        if !self.seenOnBoardingView {
            await MainActor.run {
                self.showOnboarding = true
            }
        }
    }

    func hideOnboardingSheet() {
        seenOnBoardingView = true
        UserDefaults.standard.set(true, forKey: "seenOnBoardingView")
        showOnboarding = false
    }
}

// MARK: - Static values

extension AppStore {
    static let appId = "6575345984"
    static let appAccentColorHex = "#BA1F33"
    static let appAccentColorDarkHex = "#BB2136"

    private static let customAccentColorsKey = "customAccentColors"
    private static let accentColorDataKey = "accentColorData"

    static let defaultAccentColors: [AccentColorData] = [
        AccentColorData(id: "1", name: "Classic Red", light: Color(hex: appAccentColorHex), dark: Color(hex: appAccentColorDarkHex)),
        AccentColorData(id: "2", name: "Black & White", light: Color(hex: "111111"), dark: Color(hex: "fdfdfd")),
        AccentColorData(id: "4", name: "Dark Green", light: Color(hex: "0d6b75"), dark: Color(hex: "18848f")),
        AccentColorData(id: "5", name: "Bright Orange", light: Color(hex: "fa4300"), dark: Color(hex: "fc5b21")),
    ]
}

// MARK: - UserDefaults persistence

extension AppStore {
    private func saveAccentColorData(_ data: AccentColorData) {
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: AppStore.accentColorDataKey)
        }
    }

    private static func loadAccentColorData() -> AccentColorData? {
        guard let savedData = UserDefaults.standard.data(forKey: AppStore.accentColorDataKey) else { return nil }
        return try? JSONDecoder().decode(AccentColorData.self, from: savedData)
    }

    private static func getFileURL() -> URL {
        URL.documentsDirectory.appending(path: "CustomAccentColors.json")
    }

    private func saveCustomColorsToFile() {
        do {
            let data = try JSONEncoder().encode(customColors)
            try data.write(to: AppStore.getFileURL())
        } catch {
            print("AppStore: error saving custom colors: \(error)")
        }
    }

    private static func loadCustomColorsFromFile() -> [AccentColorData] {
        let url = getFileURL()
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([AccentColorData].self, from: data)
        } catch {
            return []
        }
    }
}

// MARK: - Future GitHub color fetch (stub)

extension AppStore {
    func fetchAccentColorOptionsFromGitHub() {
        // Stub — replace with real endpoint when available
        print("AppStore.fetchAccentColorOptionsFromGitHub: not yet implemented")
    }
}


// MARK: - AccentColorMode
struct AccentColorData: Identifiable, Equatable {
    let id: String
    let name: String
    let light: Color
    let dark: Color
    var isSame: Bool {
        light == dark
    }
    
    // Manual decoding from hex strings
    enum CodingKeys: String, CodingKey {
        case id, name, lightHex, darkHex
    }
}

extension AccentColorData: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        let lightHex = try container.decode(String.self, forKey: .lightHex)
        light = Color(hex: lightHex)
        let darkHex = try container.decode(String.self, forKey: .darkHex)
        dark = Color(hex: darkHex)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(light.toHex(), forKey: .lightHex)
        try container.encode(dark.toHex(), forKey: .darkHex)
    }
}


// MARK: - WebViewColorScheme
enum WebViewColorScheme: String, CaseIterable {
    case light, dark, system
    
    var displayName: String {
        rawValue.capitalized
    }
}
