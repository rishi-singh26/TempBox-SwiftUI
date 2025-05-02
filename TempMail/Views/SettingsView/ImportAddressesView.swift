//
//  ImportAddressesView.swift
//  TempMail
//
//  Created by Rishi Singh on 02/05/25.
//

import SwiftUI

struct ImportAddressesView: View {
    @State private var base64Input = ""
    @State private var decodedString = ""
    
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    var body: some View {
        VStack(alignment: .leading) {
//            Text("Import Addresses")
//                .font(.title2)
//                .padding([.horizontal, .top])
            ScrollView {
                MacCustomSection(footer: "If the exported file name does not have any version details then it is 'Export Version 1'") {
                    HStack {
                        Text("Import from Export Version 1")
                        Spacer()
                        FilePickerView(label: {
                            Text("Choose File")
                        }, onFilePicked: { content in
                            print("File content:\n\(content)")
                        })
                    }
                }
                
                MacCustomSection(footer: "Version 2 exports will have the export version number specified in the exported file name") {
                    HStack {
                        Text("Import from Export Version 2")
                        Spacer()
                        Button("Choose File") {
                            print("Pick file")
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AccountsController.shared)
        .environmentObject(AddressesViewModel.shared)
        .environmentObject(SettingsViewModel.shared)
}
