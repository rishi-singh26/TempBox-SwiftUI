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
    @EnvironmentObject private var appController: AppController
    @EnvironmentObject private var webViewController: WebViewController
    
    /// Ones data from flutter has been migrated successfully to swftdata, set this to true
    @AppStorage("didMigrateData") private var didMigrateData: Bool = false
    
    var body: some View {
        Group {
#if os(iOS)
            Group {
                if DeviceType.isIphone {
                    IPhoneNavigtionBuilder()
                } else {
                    IPadNavigationBuilder()
                }
            }
            .onAppear(perform: handleDataImport)
#elseif os(macOS)
            MacNavigationBuilder()
#endif
        }
        .sheet(isPresented: $appController.showOnboarding, content: {
            OnboardingView(tint: .accentColor, onContinue: appController.hideOnboardingSheet)
        })
        .onAppear {
            Task(operation: appController.prfomrOnbordingCheck)
        }
    }
}

// MARK: - Navigation View Builders
extension ContentView {
#if os(iOS)
    @ViewBuilder
    private func IPhoneNavigtionBuilder() -> some View {
        NavigationStack(path: $appController.path) {
            AddressesView()
                .navigationDestination(for: Address.self) { address in
                    if address.id == KUnifiedInboxId || addressesController.showUnifiedInbox {
                        UnifiedMessagesView()
                    } else {
                        MessagesView()
                    }
                }
                .navigationDestination(for: Message.self) { message in
                    MessageDetailView()
                }
        }
    }
    
    @ViewBuilder
    private func IPadNavigationBuilder() -> some View {
        NavigationSplitView(columnVisibility: .constant(.doubleColumn)) {
            AddressesView()
        } detail: {
            NavigationStack(path: $appController.path) {
                Group {
                    if let safeAddress = addressesController.selectedAddress, safeAddress.id == KUnifiedInboxId, addressesController.showUnifiedInbox {
                        UnifiedMessagesView()
                    } else {
                        MessagesView()
                    }
                }
                .navigationDestination(for: Message.self) { message in
                    MessageDetailView()
                }
            }
        }
    }
    
#elseif os(macOS)
    @ViewBuilder
    private func MacNavigationBuilder() -> some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                AddressesView()
                Divider()
                NewAddressBtn()
            }
            .navigationSplitViewColumnWidth(min: 195, ideal: 195, max: 340)
            .toolbar(content: MacOSAddressesToolbar)
        } content: {
            Group {
                if let safeAddress = addressesController.selectedAddress {
                    if safeAddress.id == KUnifiedInboxId || addressesController.showUnifiedInbox {
                        UnifiedMessagesView()
                            .toolbar(content: MacOSUnifiedInboxToolbar)
                    } else {
                        MessagesView()
                            .toolbar(content: MacOSMessagesToolbar)
                    }
                } else {
                    Text("Please select an address")
                }
            }
            .navigationSplitViewColumnWidth(min: 320, ideal: 320, max: 400)
        } detail: {
            MessageDetailView()
                .navigationSplitViewColumnWidth(min: 440, ideal: 440)
                .toolbar(content: MacOSMessageDetailToolbar)
        }
    }
#endif
}

// MARK: - MacOS Toolbar builders
#if os(macOS)
extension ContentView {
    @ToolbarContentBuilder
    private func MacOSMessageDetailToolbar() -> some ToolbarContent {
        ToolbarItemGroup {
            Button {
                if let message = addressesController.getMessageFromStore(addressesController.selectedAddress?.id ?? "", addressesController.selectedMessage?.id ?? "") {
                    Task {
                        await addressesController.updateMessageSeenStatus(
                            messageData: message,
                            address: addressesController.selectedAddress!,
                        )
                    }
                }
            } label: {
                // Get seen status from messages store
                if let message = addressesController.getMessageFromStore(addressesController.selectedAddress?.id ?? "", addressesController.selectedMessage?.id ?? "") {
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
                messagesViewModel.selectedAddForMessDeletion = addressesController.selectedAddress!
            } label: {
                Label("Delete message", systemImage: "trash")
            }
            .help("Delete message")
            .disabled(addressesController.selectedAddress == nil || addressesController.selectedMessage == nil)
            Menu {
                Picker("Email appearance", selection: $appController.webViewAppearence) {
                    Label(WebViewColorScheme.light.displayName, systemImage: "sun.max")
                        .tag(WebViewColorScheme.light.rawValue)
                    Label(WebViewColorScheme.dark.displayName, systemImage: "moon.stars")
                        .tag(WebViewColorScheme.dark.rawValue)
                    Label(WebViewColorScheme.system.displayName, systemImage: "iphone.gen2")
                        .tag(WebViewColorScheme.system.rawValue)
                }
                .pickerStyle(.inline)
                Divider()
                Button("Message Information", systemImage: "info.circle") {
                    messageDetailController.showMessageInfoSheet = true
                }
                .help("Show message information")
                Divider()
                Button("Share", systemImage: "square.and.arrow.up") {
                    messageDetailController.showShareEmailSheet = true
                }
                .help("Share email")
            } label: {
                Image(systemName: "ellipsis.circle")
            }
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
    private func MacOSMessagesToolbar() -> some ToolbarContent {
        ToolbarItemGroup(placement: .automatic) {
            Button {
                addressesViewModel.selectedAddForInfoSheet = addressesController.selectedAddress!
                addressesViewModel.isAddressInfoSheetOpen = true
            } label: {
                Label("Address Info", systemImage: "info.circle")
            }
            .help("Address Information")
            .disabled(addressesController.selectedAddress == nil)
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
                    Task {
                        await addressesController.toggleAddressStatus(addressesController.selectedAddress!)
                    }
                } label: {
                    Label("Archive Address", systemImage: "archivebox")
                }
                .help("Archive address")
                Button(role: .destructive) {
                    addressesViewModel.showDeleteAddressAlert = true
                    addressesViewModel.selectedAddForDeletion = addressesController.selectedAddress!
                } label: {
                    Label("Delete Address", systemImage: "trash")
                }
                .help("Delete address")
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .disabled(addressesController.selectedAddress == nil)
        }
    }
    
    @ToolbarContentBuilder
    private func MacOSUnifiedInboxToolbar() -> some ToolbarContent {
        ToolbarItemGroup(placement: .automatic) {
            Button {
                Task {
                    await addressesController.fetchAddresses()
                }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise.circle")
            }
            .help("Refresh messages")
        }
    }
    
    @ToolbarContentBuilder
    private func MacOSAddressesToolbar() -> some ToolbarContent {
        ToolbarItem {
            Button {
                openWindow(id: "settings")
            } label: {
                Label("Settings", systemImage: "gear")
            }
            .help("Open settings")
        }
    }
}

struct NewAddressBtn: View {
    @EnvironmentObject private var addressesViewModel: AddressesViewModel
    
    @State private var isHovering: Bool = false
    
    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            HStack {
                Button(action: addressesViewModel.openNewAddressSheet) {
                    HStack(alignment: .center, spacing: 2) {
                        Image(systemName: "plus.circle")
                            .foregroundStyle(.primary)
                        Text("New Address")
                            .foregroundStyle(.primary)
                            .padding(.leading, 4)
                            .lineLimit(1)
                    }
                    .foregroundStyle(isHovering ? Color.primary : Color.gray)
                    .onHover(perform: { value in
                        isHovering = value
                    })
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button(action: addressesViewModel.openNewFolderSheet) {
                    Image(systemName: "folder.badge.plus")
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
            }
            
            MarkdownLinkText(markdownText: "Powered by [mail.tm](https://www.mail.tm)")
                .font(.caption2)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
    }
}
#endif

// MARK: - Import data from old app version
#if os(iOS)
extension ContentView {
    /// This on appear will read the applicatio support directory for `TempBoxExportMAJOR.txt` file.
    /// If found, it will read the contents for that file, verify that the contents are in base64, decode base64 to json, then json to ExportVersionOne
    /// After that it will save that data to swift data
    /// This is needed to migrate from the flutter version fo the application to the SwiftUI version
    /// This code will be removed one year after first relese of the SwiftUI version which is planned on 9th may, 2025. So in May 2026, this code will be removed
    private func handleDataImport() {
        guard !didMigrateData else { return }
        
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
    
    /// This method will save the address to swiftdata
    private func importAddresses(v1Data: ExportVersionOne?, completion: @escaping ([String: String]) -> Void) async {
        let addresses = (v1Data?.addresses ?? []).filter { address in
            addressesController.isAddressUnique(email: address.authenticatedUser.account.address).0
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
}
#endif
