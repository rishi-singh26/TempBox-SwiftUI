//
//  AppColorView.swift
//  TempBox
//
//  Created by Rishi Singh on 02/05/25.
//

#if os(iOS)

import SwiftUI

struct AppColorView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var appController: AppController
    @EnvironmentObject private var iapManager: IAPManager
    
    @State private var showAddColorSheet = false
    @State private var showTipJarAlert: Bool = false
    
    var sortedCustomColors: [AccentColorData] {
        appController.customColors.sorted { !$0.isSame && $1.isSame }
    }
        
    var body: some View {
        List {
            if !iapManager.hasTipped {
                Section {
                    Text(KAppColorTipJarMessage)
                }
            }
            ColorsListSection(colors: AppController.defaultAccentColors)
            Section(header: AddColorSectionHeader("Custom Colors", openAddColorSheet), footer: Text("Custom accent colors will be deleted when app is uninstalled from device")) {
                ForEach(sortedCustomColors) { accentColor in
                    ColorTile(accentColor: accentColor, hasActions: true)
                }
            }
            .headerProminence(.increased)
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Accent Color")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddColorSheet) {
            AddColorView(onColorSelect: addNewCustomColor)
                .sheetAppearanceSetup(tint: appController.accentColor(colorScheme: colorScheme))
        }
        .alert("Alert!", isPresented: $showTipJarAlert) {
            Button("Ok", role: .cancel) {}
        } message: {
            Text(KAppColorTipJarMessage)
        }
    }
    
    @ViewBuilder
    private func ColorsListSection(colors: [AccentColorData], hasActions: Bool = false) -> some View {
        Section {
            ForEach(colors) { accentColor in
                ColorTile(accentColor: accentColor, hasActions: hasActions)
            }
        } footer: {
            Text("Different colors for dark and light appearance")
        }
        .headerProminence(.increased)
    }
    
    @ViewBuilder
    private func ColorTile(accentColor: AccentColorData, hasActions: Bool) -> some View {
        // Tile
        let tile = Button {
            guard iapManager.hasTipped else {
                showTipJarAlert = true
                return
            }
            appController.selectedAccentColorData = accentColor
        } label: {
            ColorTileLabel(accentColor: accentColor)
        }
            .buttonStyle(.plain)
        
        // Delete Button
        let deleteButton = Button(role: .destructive) {
            deleteColor(color: accentColor)
        } label: {
            Label("Delete", systemImage: "trash")
        }
        
        if !hasActions {
            tile
        } else {
            tile
                .swipeActions(edge: .trailing) {
                    deleteButton
                    .tint(.red)
                }
                .contextMenu(menuItems: {
                    deleteButton
                })
        }
    }
    
    @ViewBuilder
    private func ColorTileLabel(accentColor: AccentColorData) -> some View {
        let isSelected = appController.selectedAccentColorData.id == accentColor.id
        let isLightSelected = (accentColor.isSame && isSelected) || (isSelected && colorScheme == .light)
        let isDarkSelected = (accentColor.isSame && isSelected) || (isSelected && colorScheme == .dark)
        HStack {
            Text(accentColor.name)
            Spacer()
            HStack(spacing: 10) {
                ColorPreview(backColor: .white, dotColor: accentColor.light, isSelected: isLightSelected, useBackground: !accentColor.isSame)
                if !accentColor.isSame {
                    ColorPreview(backColor: .black, dotColor: accentColor.dark, isSelected: isDarkSelected)
                }
            }
        }
    }
    
    @ViewBuilder
    private func ColorPreview(backColor: Color, dotColor: Color, isSelected: Bool, useBackground: Bool = true) -> some View {
        let preview = ZStack(alignment: .center) {
            Circle()
                .fill(dotColor)
                .frame(width: 30, height: 30)
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(Color(forBackground: dotColor))
            }
        }
        
        if useBackground {
            ZStack(alignment: .center) {
                Rectangle()
                    .fill(backColor)
                    .frame(width: 45, height: 45)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                preview
            }
        } else {
            preview
        }
    }
    
    @ViewBuilder
    private func AddColorSectionHeader(_ title: String, _ onAction: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
            Spacer()
            Button("Add", action: onAction)
        }
    }
    
    private func openAddColorSheet() {
        showAddColorSheet = true
    }
    
    private func addNewCustomColor(newColor: AccentColorData) {
        appController.addCustomColor(newColor)
    }
    
    private func editColor(color: AccentColorData) {}
    
    private func deleteColor(color: AccentColorData) {
        appController.deleteCustomColor(colorData: color)
    }
}

#Preview {
    AppColorView()
}

#endif
