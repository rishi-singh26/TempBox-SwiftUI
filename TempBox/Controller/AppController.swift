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
            saveCustomColorsToFile()
        }
    }
    
    // Onboarding view state
    @AppStorage("seenOnBoardingView") private var seenOnBoardingView: Bool = false
    @Published var showOnboarding: Bool = false
    
    init() {
        if let saved = Self.loadAccentColorData() {
            selectedAccentColorData = saved
        } else {
            selectedAccentColorData = AppController.defaultAccentColors.first!
        }
        
        #if os(iOS)
        self.customColors = Self.loadCustomColorsFromFile()
        #endif
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
    private static func getFileURL() -> URL {
        URL.documentsDirectory.appending(path: "CustomAccentColors.json")
    }
    
    private func saveCustomColorsToFile() {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(customColors)
            let url = AppController.getFileURL()
            try data.write(to: url)
        } catch {
            print("Error saving custom colors to file: \(error)")
        }
    }
    
    private static func loadCustomColorsFromFile() -> [AccentColorData] {
        let url = getFileURL()
        let decoder = JSONDecoder()
        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode([AccentColorData].self, from: data)
        } catch {
            //print("Error loading custom colors from file: \(error)")
            return []
        }
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

// MARK: - Onboarding View setup
extension AppController {
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
        showOnboarding = false
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
