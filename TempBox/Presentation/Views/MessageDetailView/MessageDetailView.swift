//
//  MessageDetailView.swift
//  TempBox
//
//  Created by Rishi Singh on 01/05/25.
//

import SwiftUI

struct MessageDetailView: View {
    @Environment(AddressStore.self) private var addressStore
    @Environment(MessageDetailViewModel.self) private var messageDetailController
    @Environment(AppStore.self) private var appStore

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        if let safeAddress = addressStore.selectedAddress, let safeMessage = addressStore.selectedMessage {
            MessageViewBuilder(message: safeMessage, address: safeAddress)
        } else {
            if addressStore.selectedAddress == nil {
                Text("Please select a address")
            } else {
                Text("Please select a message")
            }
        }
    }

    @ViewBuilder
    private func MessageViewBuilder(message: Message, address: Address) -> some View {
        @Bindable var messageDetailController = messageDetailController
        @Bindable var appStore = appStore
        let accentColor = appStore.accentColor(colorScheme: colorScheme)
        VStack(alignment: .leading, spacing: 0) {
            if let selectedMessage = addressStore.selectedMessage,
               selectedMessage.html != nil,
               selectedMessage.id == message.id {
                MessageDetailWebView(message: message)
            }
            else {
                Spacer()
            }
            if addressStore.loadingCompleteMessage {
                EmptyView()
            }
        }
        .background(Color(hex: emailColorScheme == .dark ? "#1a1a1a" : "#ffffff"))
        .sheet(isPresented: $messageDetailController.showMessageInfoSheet, content: {
            MessageInfoView(message: message)
                .sheetAppearanceSetup(tint: accentColor)
        })
        .sheet(isPresented: $messageDetailController.showAttachmentsSheet, content: {
            AttachemntListView(address: address, message: message)
                .sheetAppearanceSetup(tint: accentColor)
        })
        .sheet(isPresented: $messageDetailController.showShareEmailSheet, content: {
            ShareMessageView()
                .sheetAppearanceSetup(tint: accentColor)
        })
#if os(iOS)
        .navigationTitle(message.subject)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: {
            ToolbarItemGroup {
                if let selectedMessage = addressStore.selectedMessage,
                   selectedMessage.id == message.id,
                   selectedMessage.hasAttachments,
                   (selectedMessage.attachments?.isEmpty ?? true) == false {
                    Button("Show attachments", systemImage: "paperclip") {
                        messageDetailController.showAttachmentsSheet = true
                    }
                    .help("Show attachments list")
                }
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
            }
        })
        .preferredColorScheme(emailColorScheme)
#endif
    }

    private var emailColorScheme: ColorScheme {
        switch appStore.webViewColorScheme {
        case .dark:
            return .dark
        case .light:
            return .light
        case .system:
            return colorScheme
        }
    }
}

struct EmptyView: View {
    var body: some View {
        VStack {
            Spacer()
            ProgressView()
                .frame(width: 25, height: 25)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
