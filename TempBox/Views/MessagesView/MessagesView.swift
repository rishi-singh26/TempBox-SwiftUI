//
//  MessagesView.swift
//  TempBox
//
//  Created by Rishi Singh on 01/05/25.
//

import SwiftUI

struct MessagesView: View {
    @EnvironmentObject private var addressesController: AddressesController
    @EnvironmentObject private var addressesViewModel: AddressesViewModel
    @EnvironmentObject private var controller: MessagesViewModel
    
    private var filteredMessages: [Message] {
        guard let address = addressesController.selectedAddress else { return [] }
        
        let allMessages = addressesController.messageStore[address.id]?.messages ?? []
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
        if let safeAddress = addressesController.selectedAddress {
            MessagesViewBuilder(address: safeAddress)
        } else {
            Text("Please select an address")
        }
    }
    
    @ViewBuilder
    private func MessagesViewBuilder(address: Address) -> some View {
        Group {
            if filteredMessages.isEmpty {
                List {
                    Text("No messages")
                }
                .listStyle(.plain)
            } else {
                MessagesList(address: address)
                    .listStyle(.plain)
                    .alert("Alert!", isPresented: $controller.showDeleteMessageAlert) {
                        Button("Cancel", role: .cancel) {
                        }
                        Button("Delete", role: .destructive) {
                            Task {
                                guard let messForDeletion = controller.selectedMessForDeletion else { return }
                                await addressesController.deleteMessage(message: messForDeletion, address: address)
                                controller.selectedMessForDeletion = nil
                                controller.selectedAddForMessDeletion = nil
                                addressesController.selectedMessage = nil
                            }
                        }
                    } message: {
                        Text("Are you sure you want to delete this message?")
                    }
            }
        }
        .navigationTitle(address.ifNameElseAddress.extractUsername())
#if os(iOS)
        .refreshable {
            Task {
                await addressesController.refreshMessages(for: address)
            }
        }
        .searchable(text: $controller.searchText)
        .toolbar(content: {
            if !addressesController.showUnifiedInbox {
                ToolbarItem {
                    Button("Address Information", systemImage: "info.circle") {
                        addressesViewModel.selectedAddForInfoSheet = address
                        addressesViewModel.isAddressInfoSheetOpen = true
                    }
                    .help("Address information")
                }
            }
        })
#endif
    }
    
    @ViewBuilder
    private func MessagesList(address: Address) -> some View {
        let selectionBinding = Binding(get: {
            addressesController.selectedMessage
        }, set: { newVal in
            DispatchQueue.main.async {
                addressesController.selectedMessage = newVal
            }
        })
        Group {
#if os(iOS)
            List(filteredMessages) { message in
                MessageItemView(message: message, address: address)
            }
#elseif os(macOS)
            List(filteredMessages, selection: selectionBinding) { message in
                NavigationLink(value: message) {
                    MessageItemView(message: message, address: address)
                        .environmentObject(controller)
                }
            }
#endif
        }
    }
}
