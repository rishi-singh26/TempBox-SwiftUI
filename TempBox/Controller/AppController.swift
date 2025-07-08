//
//  AppController.swift
//  TempBox
//
//  Created by Rishi Singh on 12/06/25.
//

import SwiftUI
import StoreKit

struct AccentColorMode {
    let light: Color
    let dark: Color
}

enum WebViewColorScheme: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }
}

class AppController: ObservableObject {
    static let shared = AppController()
    static let appId: String = "6575345984"
    
    @Published var accentColor: Color = .accent
    
    @AppStorage("webViewAppearence") var webViewAppearence: String = WebViewColorScheme.system.rawValue
    var webViewColorScheme: WebViewColorScheme {
        WebViewColorScheme(rawValue: webViewAppearence) ?? .system
    }
    
    @Published var accentColorOptions: [AccentColorMode] = [
        AccentColorMode(light: Color(hex: "BA1F33"), dark: Color(hex: "BA1F33")), // Red Accent Color
        AccentColorMode(light: Color(hex: "007AFF"), dark: Color(hex: "007AFF")), // System Blue Color
        AccentColorMode(light: Color(hex: "111111"), dark: Color(hex: "fdfdfd")), // Black / White
        AccentColorMode(light: Color(hex: "0d6b75"), dark: Color(hex: "08363B")), // Dark Green Color
        AccentColorMode(light: Color(hex: "fa4300"), dark: Color(hex: "fa4300")), // Bright Orange Color
        AccentColorMode(light: Color(hex: "039603"), dark: Color(hex: "039603")) // Green Color
    ]
    
    func getchAccentColorOptions() {
        // TODO: Fetch accent colors from a JSON hosted on github
    }
}
