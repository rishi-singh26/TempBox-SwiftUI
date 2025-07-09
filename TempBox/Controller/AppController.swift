//
//  AppController.swift
//  TempBox
//
//  Created by Rishi Singh on 12/06/25.
//

import SwiftUI
import StoreKit

// MARK: - AccentColorMode

struct AccentColorData: Identifiable, Equatable {
    let id: String
    let name: String
    let color: Color
    
    // Manual decoding from hex strings
    enum CodingKeys: String, CodingKey {
        case id, name, colorHex
    }
}

extension AccentColorData: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        let colorHex = try container.decode(String.self, forKey: .colorHex)
        color = Color(hex: colorHex)
    }
}


// MARK: - WebViewColorScheme

enum WebViewColorScheme: String, CaseIterable {
    case light, dark, system
    
    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - AppController

class AppController: ObservableObject {
    static let shared = AppController()
        
    static let appId = "6575345984"
    static let appAccentColorHex = "#BA1F33"
    static let defaultAccentColors: [AccentColorData] = [
        AccentColorData(id: "1", name: "Classic Red", color: Color(hex: appAccentColorHex)),
        AccentColorData(id: "2", name: "Black & White", color: Color(hex: "111111")),
        AccentColorData(id: "3", name: "Black & White", color: Color(hex: "111111")),
        AccentColorData(id: "4", name: "Dark Green", color: Color(hex: "0d6b75")),
        AccentColorData(id: "5", name: "Bright Orange", color: Color(hex: "fa4300")),
    ]
    static let builtInColors: [AccentColorData] = [
        AccentColorData(id: "6", name: "System Blue", color: .blue),
        AccentColorData(id: "7", name: "System Green", color: .green),
        AccentColorData(id: "8", name: "System Indigo", color: .indigo),
        AccentColorData(id: "9", name: "System Mint", color: .mint),
        AccentColorData(id: "10", name: "System Orange", color: .orange),
        AccentColorData(id: "12", name: "System Pink", color: .pink),
        AccentColorData(id: "13", name: "System Purple", color: .purple),
        AccentColorData(id: "14", name: "System Red", color: .red),
        AccentColorData(id: "15", name: "System Teal", color: .teal),
        AccentColorData(id: "16", name: "System Yellow", color: .yellow),
    ]
    
    private var allAccentColors: [AccentColorData] {
        AppController.defaultAccentColors + AppController.builtInColors
    }
        
    @AppStorage("webViewAppearence") var webViewAppearence: String = WebViewColorScheme.system.rawValue
    @AppStorage("accentColorIndex") var accentColorHex: String = AppController.appAccentColorHex {
        didSet {
            updateSelectedAccentColor()
        }
    }
    
    var webViewColorScheme: WebViewColorScheme {
        WebViewColorScheme(rawValue: webViewAppearence) ?? .system
    }
    
    @Published var selectedAccentColor: Color = AppController.defaultAccentColors.first!.color
    
    init() {
        updateSelectedAccentColor()
    }
    
    private func updateSelectedAccentColor() {
        selectedAccentColor = Color(hex: accentColorHex)
    }

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

