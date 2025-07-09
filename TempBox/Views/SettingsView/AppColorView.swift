//
//  AppColorView.swift
//  TempBox
//
//  Created by Rishi Singh on 02/05/25.
//

import SwiftUI

struct AppColorView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var appController: AppController
    
    @State private var selectedColorScheme: ColorScheme? = nil
    
    private var currentColorScheme: ColorScheme {
        selectedColorScheme ?? colorScheme
    }
    
    private var toggleAppearanceBtnIcon: String {
        return currentColorScheme == .dark ? "sun.max" : "moon.stars"
    }
    
    var body: some View {
        List {
            ColorsListSection(colors: AppController.defaultAccentColors)
            ColorsListSection(colors: AppController.builtInColors)
        }
        .navigationTitle("Accent Color")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar(content: {
            ToolbarItem {
                Button {
                    updateColorSechemeSelection()
                } label: {
                    Label("Toggle Appearance", systemImage: toggleAppearanceBtnIcon)
                }

            }
        })
        .environment(\.colorScheme, currentColorScheme)
    }
    
    @ViewBuilder
    private func ColorsListSection(colors: [AccentColorData]) -> some View {
        Section {
            ForEach(colors) { accentColor in
                Button {
                    let hex = accentColor.color.toHex() ?? AppController.appAccentColorHex
                    appController.accentColorHex = hex
                } label: {
                    Label {
                        Text(accentColor.name)
                    } icon: {
                        Circle()
                            .fill(accentColor.color)
                            .frame(width: 30, height: 30, alignment: .center)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func updateColorSechemeSelection() {
        selectedColorScheme = currentColorScheme == .dark ? .light : .dark
    }
}

#Preview {
    AppColorView()
}
