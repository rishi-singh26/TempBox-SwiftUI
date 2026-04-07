//
//  AddColorView.swift
//  TempBox
//
//  Created by Rishi Singh on 12/07/25.
//

#if os(iOS)
import SwiftUI

struct AddColorView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @Environment(AppStore.self) private var appStore
    
    @State private var newColorName: String = ""
    @State private var lightColor: Color = .white
    @State private var darkColor: Color = .black
    @State private var useSameColor: Bool = false
        
    var body: some View {
        let accentColor = appStore.accentColor(colorScheme: colorScheme)
        NavigationView {
            Form {
                TextField("Color name", text: $newColorName)
                    .textInputAutocapitalization(.words)
                ColorPicker("Select \(useSameColor ?  "" : "light ")color", selection: $lightColor, supportsOpacity: false)
                if !useSameColor {
                    ColorPicker("Select dark color", selection: $darkColor, supportsOpacity: false)
                }
                
                Section {
                    Toggle("Use same color", isOn: $useSameColor.animation())
                } footer: {
                    Text("Use same color in light and dark appearance")
                }
            }
            .navigationTitle("Add Custom Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", systemImage: "checkmark") {
                        addNewCustomColor(AccentColorData(
                            id: UUID().uuidString,
                            name: newColorName,
                            light: lightColor,
                            dark: useSameColor ? lightColor : darkColor
                        ))
                        dismiss()
                    }
                    .tint(accentColor)
                    .disabled(isInValidInput)
                }
            }
        }
    }
    
    private func addNewCustomColor(_ newColor: AccentColorData) {
        appStore.addCustomColor(newColor)
    }
    
    private var isInValidInput: Bool {
        if useSameColor {
            return newColorName.isEmpty || lightColor == .white
        } else {
            return newColorName.isEmpty || lightColor == .white || darkColor == .black
        }
    }
}

#Preview {
    AddColorView()
}
#endif
