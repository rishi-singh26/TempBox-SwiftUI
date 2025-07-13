//
//  AppController.swift
//  TempBox
//
//  Created by Rishi Singh on 12/06/25.
//

import SwiftUI
import StoreKit

class AppController: ObservableObject {
    static let shared = AppController()
    
    /// Used for navigation on iPhone only
    @Published var path = NavigationPath()
    
    @AppStorage("hasTippedSmall") private(set) var hasTippedSmall: Bool = false
    @AppStorage("hasTippedMedium") private(set) var hasTippedMedium: Bool = false
    @AppStorage("hasTippedLarge") private(set) var hasTippedLarge: Bool = false
    var hasTipped: Bool {
        hasTippedSmall || hasTippedMedium || hasTippedLarge
    }
        
    @AppStorage("webViewAppearence") var webViewAppearence: String = WebViewColorScheme.system.rawValue
    var webViewColorScheme: WebViewColorScheme {
        WebViewColorScheme(rawValue: webViewAppearence) ?? .system
    }

    @Published var selectedAccentColorData: AccentColorData {
        didSet {
            saveAccentColorData(selectedAccentColorData)
        }
    }
    @Published var customColors: [AccentColorData] = [] {
        didSet {
            saveCustomColors()
        }
    }
    
    init() {
        if let saved = Self.loadAccentColorData() {
            selectedAccentColorData = saved
        } else {
            selectedAccentColorData = AppController.defaultAccentColors.first!
        }
        
        self.customColors = Self.loadCustomColors()
    }
    
    func addCustomColor(_ color: AccentColorData) {
        guard !customColors.contains(color) else { return }
        customColors.append(color)
    }
    
    func deleteCustomColor(colorData: AccentColorData) {
        customColors.removeAll { $0.id == colorData.id }
    }
    
    func accentColor(colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark:
            return selectedAccentColorData.dark
        case .light:
            return selectedAccentColorData.light
        @unknown default:
            return Color(hex: AppController.appAccentColorHex)
        }
    }
    
    // Tipped features
    func updateTipStatus(for productId: String, status: Bool) {
        if productId.lowercased().contains("small") {
            hasTippedSmall = status
        } else if productId.lowercased().contains("medium") {
            hasTippedMedium = status
        } else if productId.lowercased().contains("large") {
            hasTippedLarge = status
        } else {
            // Nothing
        }
        
        // Reset accent color and app icon of tip not present or removed
        if !hasTipped {
            selectedAccentColorData = AppController.defaultAccentColors.first!
        }
    }
    
    func updateUnlockedFeatures(for productIds: [String]) {
        productIds.forEach { updateTipStatus(for: $0, status: true) }
    }
}

// MARK: - Static values
extension AppController {
    static let appId = "6575345984"
    static let appAccentColorHex = "#BA1F33"
    static let appAccentColorDarkHex = "#BB2136"
    
    static private let customAccentColorsKey = "customAccentColors"
    static private let accentColorDataKey = "accentColorData"
    
    static let defaultAccentColors: [AccentColorData] = [
         AccentColorData(id: "1", name: "Classic Red", light: Color(hex: appAccentColorHex), dark: Color(hex: appAccentColorDarkHex)),
         AccentColorData(id: "2", name: "Black & White", light: Color(hex: "111111"), dark: Color(hex: "fdfdfd")), // Black / White
         AccentColorData(id: "4", name: "Dark Green", light: Color(hex: "0d6b75"), dark: Color(hex: "18848f")), // Dark Green Color
         AccentColorData(id: "5", name: "Bright Orange", light: Color(hex: "fa4300"), dark: Color(hex: "fc5b21")), // Bright Orange Color
    ]
}

// MARK: - UserDefaultes reader and writer
extension AppController {
    // Selected color
    private func saveAccentColorData(_ data: AccentColorData) {
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: AppController.accentColorDataKey)
        }
    }
    
    private static func loadAccentColorData() -> AccentColorData? {
        guard let savedData = UserDefaults.standard.data(forKey: AppController.accentColorDataKey) else {
            return nil
        }
        return try? JSONDecoder().decode(AccentColorData.self, from: savedData)
    }
    
    
    // Custom colors
    private func saveCustomColors() {
        if let encoded = try? JSONEncoder().encode(customColors) {
            UserDefaults.standard.set(encoded, forKey: AppController.customAccentColorsKey)
        }
    }

    private static func loadCustomColors() -> [AccentColorData] {
        guard let data = UserDefaults.standard.data(forKey: AppController.customAccentColorsKey) else {
            return []
        }
        return (try? JSONDecoder().decode([AccentColorData].self, from: data)) ?? []
    }
}

// MARK: - API Colors
extension AppController {
    // MARK: - Future Fetching
    func fetchAccentColorOptionsFromGitHub() {
        // Example URL: Replace with actual endpoint
        guard let url = URL(string: "https://raw.githubusercontent.com/yourname/yourrepo/main/colors.json") else {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Fetch error: \(error.localizedDescription)")
                return
            }
            guard let data = data else { return }

            do {
                // Update decoder depending on your JSON format
                let decodedColors = try JSONDecoder().decode([AccentColorData].self, from: data)
                DispatchQueue.main.async {
                    // You may want to merge, replace, or selectively update
                    print("Fetched \(decodedColors.count) accent colors.")
                    // self.allAccentColors = decodedColors + AppController.builtInColors
                }
            } catch {
                print("JSON decode error: \(error)")
            }
        }.resume()
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
