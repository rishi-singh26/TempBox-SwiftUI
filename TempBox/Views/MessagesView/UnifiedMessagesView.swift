//
//  UnifiedMessagesView.swift
//  TempBox
//
//  Created by Rishi Singh on 26/07/25.
//

import SwiftUI

struct UnifiedMessagesView: View {
    @EnvironmentObject private var addressesController: AddressesController
    @EnvironmentObject private var controller: MessagesViewModel
    
    private var allMessages: [Message] {
        addressesController.messageStore.values
            .flatMap { $0.messages }
            .sorted { $0.createdAt > $1.createdAt }
    }
    
    private var filteredMessages: [Message] {
        if allMessages.isEmpty {
            return allMessages
        }
        if controller.searchText.isEmpty {
            return allMessages
        } else {
            let searchQuery = controller.searchText.lowercased()
            return allMessages.filter { message in
                let subMatches = message.subject.lowercased().contains(searchQuery)
                let fromMatches = message.fromAddress.contains(searchQuery)
                return subMatches || fromMatches
            }
        }
    }
    
    var body: some View {
        Group {
            if filteredMessages.isEmpty {
                List {
                    Text("No messages")
                }
                .listStyle(.plain)
            } else {
                MessagesList()
                    .listStyle(.plain)
            }
        }
        .alert("Alert!", isPresented: $controller.showDeleteMessageAlert) {
            Button("Cancel", role: .cancel) {
            }
            Button("Delete", role: .destructive) {
                Task {
                    guard let messForDeletion = controller.selectedMessForDeletion, let addForMessDel = controller.selectedAddForMessDeletion else { return }
                    await addressesController.deleteMessage(message: messForDeletion, address: addForMessDel)
                    controller.selectedMessForDeletion = nil
                    controller.selectedAddForMessDeletion = nil
                    addressesController.selectedMessage = nil
                }
            }
        } message: {
            Text("Are you sure you want to delete this message?")
        }
        .navigationTitle("All Inboxes")
#if os(iOS)
        .searchable(text: $controller.searchText)
        .refreshable {
            Task {
                await addressesController.fetchAddresses()
            }
        }
#endif
    }
    
    @ViewBuilder
    private func MessagesList() -> some View {
        let selectionBinding = Binding(get: {
            addressesController.selectedMessage
        }, set: { newVal in
            Task {
                await addressesController.updateMessageSelection(message: newVal)
            }
        })
        
        Group {
#if os(iOS)
            List(filteredMessages) { message in
                if let address = addressesController.getAddress(withMsgID: message.id) {
                    MessageItemView(message: message, address: address)
                }
            }
#elseif os(macOS)
            List(filteredMessages, selection: selectionBinding) { message in
                if let address = addressesController.getAddress(withMsgID: message.id) {
                    NavigationLink(value: message) {
                        MessageItemView(message: message, address: address)
                            .environmentObject(controller)
                    }
                }
            }
#endif
        }
    }
}
