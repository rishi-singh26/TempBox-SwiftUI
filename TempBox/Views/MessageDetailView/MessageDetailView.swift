//
//  MessageDetailView.swift
//  TempBox
//
//  Created by Rishi Singh on 01/05/25.
//

import SwiftUI

struct MessageDetailView: View {
    @EnvironmentObject private var addressesController: AddressesController
    @EnvironmentObject private var messageDetailController: MessageDetailViewModel
    @EnvironmentObject var appController: AppController
    @Environment(\.colorScheme) var colorScheme

    let message: Message
    let address: Address
    
    private var messageFromStore: Message? {
        addressesController.getMessageFromStore(address.id, message.id)
    }
        
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MessageHeaderView(message: message)
            Text(message.subject)
                .font(.title3.bold())
                .padding(.vertical, 4)
                .foregroundStyle(Color(hex: emailColorScheme == .light ? "#000000" : "#ffffff"))
            if let selectedMessage = addressesController.selectedCompleteMessage,
               selectedMessage.id == message.id,
               let html = selectedMessage.html?.first {
                WebView(html: html, appearance: emailColorScheme)
            }
            else {
                Spacer()
            }
            if addressesController.loadingCompleteMessage {
                EmptyView()
            }
        }
        .background(Color(hex: emailColorScheme == .dark ? "#1a1a1a" : "#ffffff"))
        .onAppear(perform: updateMessageSeenStatus)
        .sheet(isPresented: $messageDetailController.showMessageInfoSheet, content: {
            MessageInfoView(message: message)
                .environmentObject(messageDetailController)
                .accentColor(appController.accentColor(colorScheme: colorScheme))
        })
        .sheet(isPresented: $messageDetailController.showAttachmentsSheet, content: {
            AttachemntListView(address: address, message: message)
                .environmentObject(messageDetailController)
                .accentColor(appController.accentColor(colorScheme: colorScheme))
        })
#if os(iOS)
        .toolbar(content: {
            ToolbarItemGroup {
                if let selectedMessage = addressesController.selectedCompleteMessage,
                   selectedMessage.id == message.id, selectedMessage.hasAttachments {
                    Button("Show attachments", systemImage: "paperclip") {
                        messageDetailController.showAttachmentsSheet = true
                    }
                    .help("Show attachments list")
                }
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
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        })
        .navigationBarTitleDisplayMode(.inline)
#elseif os(macOS)
        .onChange(of: addressesController.selectedMessage, { _, _ in
            updateMessageSeenStatus()
        })
#endif
    }
    
    private func updateMessageSeenStatus() {
        Task {
#if os(iOS)
            await addressesController.fetchCompleteMessage(of: message, address: address)
#endif
            if let messageFromStore = messageFromStore, !messageFromStore.seen {
                await addressesController.updateMessageSeenStatus(messageData: messageFromStore, address: address, seen: true)
            }
        }
    }
    
    private var emailColorScheme: ColorScheme {
        switch appController.webViewColorScheme {
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

#Preview {
    ContentView()
        .environmentObject(AddressesController.shared)
        .environmentObject(AddressesViewModel.shared)
}
