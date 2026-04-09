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
    @Environment(AddressStore.self) private var addressStore
    @Environment(AddressesViewModel.self) private var addressesViewModel
    @Environment(SettingsViewModel.self) private var settingsViewModel
    @Environment(MessagesViewModel.self) private var messagesViewModel
    @Environment(MessageDetailViewModel.self) private var messageDetailController
    @Environment(AppStore.self) private var appStore
    @EnvironmentObject private var webViewController: WebViewController

    /// Once data from Flutter has been migrated successfully to SwiftData, set this to true
    @AppStorage("didMigrateData") private var didMigrateData: Bool = false

    var body: some View {
        @Bindable var appStore = appStore

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
        .sheet(isPresented: $appStore.showOnboarding, onDismiss: {
            Task(operation: appStore.performDisclaimerCheck)
        }, content: {
            OnboardingView(tint: .accentColor, onContinue: appStore.hideOnboardingSheet)
        })
        .sheet(isPresented: $appStore.showDisclaimer, content: {
            DisclaimerView(tint: .accentColor, onAccept: appStore.hideDisclaimerSheet)
        })
        .onAppear {
            Task(operation: appStore.prfomrOnbordingCheck)
        }
    }
}

// MARK: - Navigation View Builders
extension ContentView {
#if os(iOS)
    @ViewBuilder
    private func IPhoneNavigtionBuilder() -> some View {
        @Bindable var appStore = appStore

        NavigationStack(path: $appStore.path) {
            AddressesView()
                .navigationDestination(for: Address.self) { address in
                    if address.id == KUnifiedInboxId || addressStore.showUnifiedInbox {
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
        @Bindable var appStore = appStore

        NavigationSplitView(columnVisibility: .constant(.doubleColumn)) {
            AddressesView()
        } detail: {
            NavigationStack(path: $appStore.path) {
                Group {
                    if let safeAddress = addressStore.selectedAddress,
                       safeAddress.id == KUnifiedInboxId,
                       addressStore.showUnifiedInbox {
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
        @Bindable var appStore = appStore
        @Bindable var messagesViewModel = messagesViewModel
        @Bindable var messageDetailController = messageDetailController

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
                if let safeAddress = addressStore.selectedAddress {
                    if safeAddress.id == KUnifiedInboxId || addressStore.showUnifiedInbox {
                        UnifiedMessagesView()
                    } else {
                        MessagesView()
                    }
                } else {
                    List { Text("Please select an address") }
                }
            }
            .toolbar(content: MacOSMessagesToolbar)
            .navigationSplitViewColumnWidth(min: 320, ideal: 320, max: 400)
        } detail: {
            MessageDetailView()
                .navigationSplitViewColumnWidth(min: 440, ideal: 740)
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
        @Bindable var appStore = appStore
        @Bindable var messageDetailController = messageDetailController

        ToolbarItemGroup {
            Button {
                if let message = addressStore.selectedMessage {
                    Task {
                        await addressStore.updateMessageSeenStatus(messageData: message)
                    }
                }
            } label: {
                if let message = addressStore.selectedMessage {
                    Label(message.seen ? "Mark as unread" : "Mark as read", systemImage: message.seen ? "envelope.badge" : "envelope.open")
                } else {
                    Label("Mark as read/unread", systemImage: "envelope.badge")
                }
            }
            .help("Mark as read/unread")
            .disabled(addressStore.selectedAddress == nil || addressStore.selectedMessage == nil)

            Button(role: .destructive) {
                messagesViewModel.showDeleteMessageAlert = true
                messagesViewModel.selectedMessForDeletion = addressStore.selectedMessage!
            } label: {
                Label("Delete message", systemImage: "trash")
            }
            .help("Delete message")
            .disabled(addressStore.selectedAddress == nil || addressStore.selectedMessage == nil)

            Menu {
                Picker("Email appearance", selection: $appStore.webViewAppearence) {
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
            .disabled(addressStore.selectedAddress == nil || addressStore.selectedMessage == nil)

            if let selectedMessage = addressStore.selectedMessage, selectedMessage.hasAttachments {
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
                addressesViewModel.selectedAddForInfoSheet = addressStore.selectedAddress!
                addressesViewModel.isAddressInfoSheetOpen = true
            } label: {
                Label("Address Info", systemImage: "info.circle")
            }
            .help("Address Information")
            .disabled(addressStore.selectedAddress == nil || addressStore.selectedAddress?.id == KUnifiedInboxId || addressStore.showUnifiedInbox)

            Button {
                Task {
                    if addressStore.selectedAddress?.id == KUnifiedInboxId || addressStore.showUnifiedInbox {
                        await addressStore.fetchAddresses()
                    } else {
                        await addressStore.fetchMessages(for: addressStore.selectedAddress!)
                    }
                }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise.circle")
            }
            .help("Refresh messages")
            .disabled(addressStore.selectedAddress == nil)

            Menu {
                Button {
                    Task {
                        await addressStore.toggleArchiveStatus(addressStore.selectedAddress!)
                    }
                } label: {
                    Label("Archive Address", systemImage: "archivebox")
                }
                .help("Archive address")
                Button(role: .destructive) {
                    addressesViewModel.showDeleteAddressAlert = true
                    addressesViewModel.selectedAddForDeletion = addressStore.selectedAddress!
                } label: {
                    Label("Delete Address", systemImage: "trash")
                }
                .help("Delete address")
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .disabled(addressStore.selectedAddress == nil || addressStore.selectedAddress?.id == KUnifiedInboxId || addressStore.showUnifiedInbox)
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
    @Environment(AddressesViewModel.self) private var addressesViewModel

    @State private var isHovering: Bool = false

    var body: some View {
        @Bindable var addressesViewModel = addressesViewModel

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
                .keyboardShortcut("N", modifiers: .command)
                .buttonStyle(.plain)

                Spacer()

                Button(action: addressesViewModel.openNewFolderSheet) {
                    Image(systemName: "folder.badge.plus")
                        .foregroundStyle(Color.accentColor)
                }
                .keyboardShortcut("F", modifiers: .command)
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
                        await importAddresses(v1Data: v1Data) { _ in }
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

    private func importAddresses(v1Data: ExportVersionOne?, completion: @escaping ([String: String]) -> Void) async {
        let addresses = (v1Data?.addresses ?? []).filter { address in
            addressStore.isAddressUnique(email: address.authenticatedUser.account.address).0
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
                    let (status, message) = await addressStore.loginAndSave(v1Address: address)
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
