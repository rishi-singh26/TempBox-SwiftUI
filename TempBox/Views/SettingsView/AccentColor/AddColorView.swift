//
//  AddColorView.swift
//  TempBox
//
//  Created by Rishi Singh on 12/07/25.
//

import SwiftUI

struct AddColorView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var newColorName: String = ""
    @State private var lightColor: Color = .white
    @State private var darkColor: Color = .black
    
    var onColorSelect: (AccentColorData) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Color name", text: $newColorName)
                ColorPicker("Select light color", selection: $lightColor, supportsOpacity: false)
                ColorPicker("Select dark color", selection: $darkColor, supportsOpacity: false)
            }
            .navigationTitle("Add Custom Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onColorSelect(AccentColorData(id: UUID().uuidString, name: newColorName, light: lightColor, dark: darkColor))
                        dismiss()
                    }
                    .disabled(newColorName.isEmpty || lightColor == .white || darkColor == .black)
                }
            }
        }
    }
}

#Preview {
    AddColorView { newColor in
        print(newColor.id)
        print(newColor.name)
        print(newColor.light.toHex() ?? "")
        print(newColor.dark.toHex() ?? "")
    }
}
