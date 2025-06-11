//
//  ContentView.swift
//  TempMail
//
//  Created by Rishi Singh on 01/05/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject private var addressesController: AddressesController
    @EnvironmentObject private var addressesViewModel: AddressesViewModel
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    
    /// Ones data from flutter has been migrated successfully to swftdata, set this to true
    @AppStorage("didMigrateData") var didMigrateData: Bool = false
    
    var body: some View {
#if os(iOS)
        NavigationView {
            AddressesView()
            /// This on appear will read the applicatio support directory for `TempBoxExportMAJOR.txt` file.
            /// If found, it will read the contents for that file, verify that the contents are in base64, decode base64 to json, then json to ExportVersionOne
            /// After that it will save that data to swift data
            /// This is needed to migrate from the flutter version fo the application to the SwiftUI version
            /// This code will be removed one year after first relese of the SwiftUI version which is planned on 9th may, 2025. So in May 2026, this code will be removed
                .onAppear {
                    if (didMigrateData) { return }
                    let fileName = "TempBoxExportMAJOR.txt"
                    
                    do {
                        let fileManager = FileManager.default
                        let appSupportURL = try fileManager.url(
                            for: .applicationSupportDirectory,
                            in: .userDomainMask,
                            appropriateFor: nil,
                            create: true
                        )
                        
                        let fileURL = appSupportURL.appendingPathComponent(fileName)
                        
                        if fileManager.fileExists(atPath: fileURL.path) {
                            let data = try Data(contentsOf: fileURL)
                            if let content = String(data: data, encoding: .utf8) {
                                print(content)
                                let (v1Data, _, message) = ImportExportService.decodeDataForImport(from: content)
                                print(v1Data ?? "Version one data not available", message)
                                Task {
                                    await importAddresses(v1Data: v1Data) { _ in
                                    }
                                }
                            } else {
                                didMigrateData = true
                                print("Unable to decode file contents.")
                            }
                        } else {
                            didMigrateData = true
                            print("File does not exist.")
                        }
                        
                    } catch {
                        didMigrateData = true
                        print("Error: \(error.localizedDescription)")
                    }
                }
        }
#elseif os(macOS)
        NavigationSplitView {
            NewAddressBtn()
            AddressesView()
            MarkdownLinkText(markdownText: "Powered by [mail.tm](https://www.mail.tm)")
                .font(.footnote)
        } content: {
            Group {
                if let safeAddress = addressesController.selectedAddress {
                    MessagesView(address: safeAddress)
                } else {
                    Text("Address not selected")
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    Button {
                        Task {
                            await addressesController.fetchMessages(for: addressesController.selectedAddress!)
                        }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise.circle")
                    }
                    .disabled(addressesController.selectedAddress == nil)
                    Button {
                        addressesViewModel.selectedAddForInfoSheet = addressesController.selectedAddress!
                        addressesViewModel.isAddressInfoSheetOpen = true
                    } label: {
                        Label("Address Info", systemImage: "info.circle")
                    }
                    .disabled(addressesController.selectedAddress == nil)
                    Button {
                        addressesViewModel.selectedAddForEditSheet = addressesController.selectedAddress!
                        addressesViewModel.isEditAddressSheetOpen = true
                    } label: {
                        Label("Edit", systemImage: "pencil.circle")
                    }
                    .disabled(addressesController.selectedAddress == nil)
                    Button {
                    } label: {
                        Label("Archive", systemImage: "archivebox")
                    }
                    .disabled(true)
                    Button(role: .destructive) {
                        addressesViewModel.showDeleteAddressAlert = true
                        addressesViewModel.selectedAddForDeletion = addressesController.selectedAddress!
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .disabled(addressesController.selectedAddress == nil)
                }
            }
        } detail: {
            if let safeMessage = addressesController.selectedMessage, let safeAddress = addressesController.selectedAddress {
                MessageDetailView(message: safeMessage, address: safeAddress)
            } else {
                Text("No message selected")
            }
        }
#endif
    }
    
//#if os(iOS)
    /// This method will save the address to swiftdata
    func importAddresses(v1Data: ExportVersionOne?, completion: @escaping ([String: String]) -> Void) async {
        let addresses = (v1Data?.addresses ?? []).filter { address in
            let idMatches = addressesController.addresses.first(where: { existingAddress in
                existingAddress.id == address.id
            })
            return idMatches == nil
        }
        if addresses.isEmpty {
            didMigrateData = true
            completion([:])
            return
        }
        
        var errorMap: [String: String] = [:]
        
        await withTaskGroup(of: (String, String?)?.self) { group in
            for address in addresses {
                group.addTask {
                    let (status, message) = await addressesController.loginAndSaveAddress(address: address)
                    return status ? nil : (address.id, message)
                }
            }
            
            for await result in group {
                if let (id, message) = result {
                    errorMap[id] = message
                }
            }
        }
        
        settingsViewModel.selectedV1Addresses.removeAll()
        didMigrateData = true
        completion(errorMap)
    }
//#endif
}

struct NewAddressBtn: View {
    @EnvironmentObject private var addressesViewModel: AddressesViewModel
    
    var body: some View {
        Button(action: addressesViewModel.openNewAddressSheet, label: {
            VStack(alignment: .leading) {
                HStack {
                    Text("New Address")
                        .foregroundStyle(.primary)
                        .padding(.leading, 4)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.primary)
                }
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(6)
            }
        })
        .padding(.horizontal)
        .padding(.vertical, 5)
        .buttonStyle(.plain)
        .keyboardShortcut(.init("n", modifiers: [.command, .shift]))
    }
}

#Preview {
    ContentView()
        .environmentObject(AddressesController.shared)
        .environmentObject(SettingsViewModel.shared)
        .environmentObject(AddressesViewModel.shared)
}
