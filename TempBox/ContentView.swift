//
//  ContentView.swift
//  TempBox
//
//  Created by Rishi Singh on 01/05/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.openWindow) var openWindow
    @EnvironmentObject private var addressesController: AddressesController
    @EnvironmentObject private var addressesViewModel: AddressesViewModel
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    @EnvironmentObject private var messageDetailController: MessageDetailViewModel
    @EnvironmentObject private var messagesViewModel: MessagesViewModel
    
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
            VStack {
                NewAddressBtn()
                AddressesView()
                MarkdownLinkText(markdownText: "Powered by [mail.tm](https://www.mail.tm)")
                    .font(.footnote)
            }
            .navigationSplitViewColumnWidth(min: 195, ideal: 195, max: 340)
            .toolbar {
                ToolbarItem {
                    Button {
                        openWindow(id: "settings")
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                    .help("Open settings")
                }
            }
        } content: {
            Group {
                if let safeAddress = addressesController.selectedAddress {
                    MessagesView(address: safeAddress)
                } else {
                    Text("Address not selected")
                }
            }
            .navigationSplitViewColumnWidth(min: 290, ideal: 290, max: 400)
            .toolbar(content: MacOSMessagesToolbar)
        } detail: {
            Group {
                if let safeMessage = addressesController.selectedMessage, let safeAddress = addressesController.selectedAddress {
                    MessageDetailView(message: safeMessage, address: safeAddress)
                } else {
                    Text("No message selected")
                }
            }
            .navigationSplitViewColumnWidth(min: 440, ideal: 440)
            .toolbar(content: MacOSMessageDetailToolbar)
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
    
    
#if os(macOS)
    @ToolbarContentBuilder
    func MacOSMessageDetailToolbar() -> some ToolbarContent {
        ToolbarItemGroup {
            Button("Message Information", systemImage: "info.circle") {
                messageDetailController.showMessageInfoSheet = true
            }
            .help("Message information")
            .disabled(addressesController.selectedAddress == nil || addressesController.selectedMessage == nil)
            Button {
                Task {
                    await addressesController.updateMessageSeenStatus(
                        messageData: addressesController.selectedMessage!,
                        address: addressesController.selectedAddress!,
                        seen: !addressesController.selectedMessage!.seen
                    )
                }
            } label: {
                if let message = addressesController.selectedMessage {
                    Label(message.seen ? "Mark as unread" : "Mark as read", systemImage: message.seen ? "envelope.badge" : "envelope.open")
                } else {
                    Label("Mark as read/unread", systemImage: "envelope.badge")
                }
            }
            .help("Mark as read/unread")
            .disabled(addressesController.selectedAddress == nil || addressesController.selectedMessage == nil)
            Button(role: .destructive) {
                messagesViewModel.showDeleteMessageAlert = true
                messagesViewModel.selectedMessForDeletion = addressesController.selectedMessage!
            } label: {
                Label("Delete message", systemImage: "trash")
            }
            .help("Delete message")
            .disabled(addressesController.selectedAddress == nil || addressesController.selectedMessage == nil)
            if let selectedMessage = addressesController.selectedCompleteMessage, selectedMessage.hasAttachments {
                Button("Show attachments", systemImage: "paperclip") {
                    messageDetailController.showAttachmentsSheet = true
                }
                .help("Show attachments")
            }
        }
    }
    
    @ToolbarContentBuilder
    func MacOSMessagesToolbar() -> some ToolbarContent {
        ToolbarItemGroup(placement: .automatic) {
            Button {
                Task {
                    await addressesController.refreshMessages(for: addressesController.selectedAddress!)
                }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise.circle")
            }
            .help("Refresh messages")
            .disabled(addressesController.selectedAddress == nil)
            Menu {
                Button {
                    addressesViewModel.selectedAddForInfoSheet = addressesController.selectedAddress!
                    addressesViewModel.isAddressInfoSheetOpen = true
                } label: {
                    Label("Address Info", systemImage: "info.circle")
                }
                .help("Address Information")
                .disabled(addressesController.selectedAddress == nil)
                Button {
                    addressesViewModel.selectedAddForEditSheet = addressesController.selectedAddress!
                    addressesViewModel.isEditAddressSheetOpen = true
                } label: {
                    Label("Edit Address", systemImage: "pencil.circle")
                }
                .help("Edit address name")
                .disabled(addressesController.selectedAddress == nil)
                Button {
                    Task {
                        await addressesController.toggleAddressStatus(addressesController.selectedAddress!)
                    }
                } label: {
                    Label("Archive Address", systemImage: "archivebox")
                }
                .help("Archive address")
                .disabled(addressesController.selectedAddress == nil)
                Button(role: .destructive) {
                    addressesViewModel.showDeleteAddressAlert = true
                    addressesViewModel.selectedAddForDeletion = addressesController.selectedAddress!
                } label: {
                    Label("Delete Address", systemImage: "trash")
                }
                .help("Delete address")
                .disabled(addressesController.selectedAddress == nil)
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
#endif
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
        .help("Create new address or login to an address")
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
        .environmentObject(AppController.shared)
}
