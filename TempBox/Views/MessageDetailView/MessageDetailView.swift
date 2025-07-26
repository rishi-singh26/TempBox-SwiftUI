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
    @EnvironmentObject private var webViewController: WebViewController
    
    @Environment(\.colorScheme) var colorScheme
        
    var body: some View {
        if let safeAddress = addressesController.selectedAddress, let safeMessage = addressesController.selectedMessage {
            MessageViewBuilder(message: safeMessage, address: safeAddress)
        } else {
            if addressesController.selectedAddress == nil {
                Text("Please select a address")
            } else {
                Text("Please select a message")
            }
        }
    }
    
    @ViewBuilder
    private func MessageViewBuilder(message: Message, address: Address) -> some View {
        let accentColor = appController.accentColor(colorScheme: colorScheme)
        VStack(alignment: .leading, spacing: 0) {
            MessageHeaderView(message: message)
            Text(message.subject)
                .font(.title3.bold())
                .padding(.vertical, 4)
                .foregroundStyle(Color(hex: emailColorScheme == .light ? "#000000" : "#ffffff"))
            if let selectedMessage = addressesController.selectedCompleteMessage,
               selectedMessage.id == message.id,
               let html = selectedMessage.html?.first {
                WebView(html: html, appearance: emailColorScheme, controller: webViewController)
            }
            else {
                Spacer()
            }
            if addressesController.loadingCompleteMessage {
                EmptyView()
            }
        }
        .background(Color(hex: emailColorScheme == .dark ? "#1a1a1a" : "#ffffff"))
        .sheet(isPresented: $messageDetailController.showMessageInfoSheet, content: {
            MessageInfoView(message: message)
                .environmentObject(messageDetailController)
                .sheetAppearanceSetup(tint: accentColor)
        })
        .sheet(isPresented: $messageDetailController.showAttachmentsSheet, content: {
            AttachemntListView(address: address, message: message)
                .environmentObject(messageDetailController)
                .sheetAppearanceSetup(tint: accentColor)
        })
        .sheet(isPresented: $messageDetailController.showShareEmailSheet, content: {
            ShareMessageView()
                .sheetAppearanceSetup(tint: accentColor)
        })
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
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
#endif
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
