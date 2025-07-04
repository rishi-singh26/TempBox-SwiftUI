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

    let message: Message
    let address: Address
        
    var body: some View {
        VStack(alignment: .leading) {
            MessageHeaderView(message: message)
            Text(message.subject)
                .font(.title3.bold())
            if let selectedMessage = addressesController.selectedCompleteMessage,
               selectedMessage.id == message.id,
               let html = selectedMessage.html?.first {
                    WebView(html: html)
            }
            else {
                Spacer()
            }
            if addressesController.loadingCompleteMessage {
                EmptyView()
            }
        }
        .onAppear(perform: {
            Task {
                await addressesController.fetchCompleteMessage(of: message, address: address)
                await addressesController.updateMessageSeenStatus(messageData: message, address: address, seen: true)
            }
        })
        .sheet(isPresented: $messageDetailController.showMessageInfoSheet, content: {
            MessageInfoView(message: message)
                .environmentObject(messageDetailController)
        })
        .sheet(isPresented: $messageDetailController.showAttachmentsSheet, content: {
            AttachemntListView(address: address, message: message)
                .environmentObject(messageDetailController)
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
                Button("Message Information", systemImage: "info.circle") {
                    messageDetailController.showMessageInfoSheet = true
                }
                .help("Show message information")
            }
        })
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
}

struct EmptyView: View {
    var body: some View {
        VStack {
            Spacer()
            ProgressView()
                .frame(width: 25, height: 25)
                .tint(.red)
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
