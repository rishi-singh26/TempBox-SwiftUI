//
//  AppController.swift
//  TempMail
//
//  Created by Rishi Singh on 12/06/25.
//

import SwiftUI

struct AccentColorMode {
    let light: Color
    let dark: Color
}

class AppController: ObservableObject {
    static let shared = AppController()
    
    @Published var accentColor: Color = .accent
    
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
