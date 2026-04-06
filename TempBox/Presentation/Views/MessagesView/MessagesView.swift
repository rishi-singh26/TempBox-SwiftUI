//
//  MessagesView.swift
//  TempBox
//
//  Created by Rishi Singh on 01/05/25.
//

import SwiftUI

struct MessagesView: View {
    @Environment(AddressStore.self) private var addressStore
    @Environment(AddressesViewModel.self) private var addressesViewModel
    @Environment(MessagesViewModel.self) private var controller

    private var filteredMessages: [Message] {
        guard let address = addressStore.selectedAddress else { return [] }

        let allMessages = (address.messages ?? []).sorted { ($0.created ?? .distantPast) > ($1.created ?? .distantPast) }
        if controller.searchText.isEmpty { return allMessages }

        let searchQuery = controller.searchText.lowercased()
        return allMessages.filter { message in
            message.subject.lowercased().contains(searchQuery) ||
            message.fromAddress.contains(searchQuery)
        }
    }

    var body: some View {
        if let safeAddress = addressStore.selectedAddress {
            MessagesViewBuilder(address: safeAddress)
        } else {
            Text("Please select an address")
        }
    }

    @ViewBuilder
    private func MessagesViewBuilder(address: Address) -> some View {
        @Bindable var controller = controller

        Group {
            if filteredMessages.isEmpty {
                List { Text("No messages") }
                    .listStyle(.plain)
            } else {
                MessagesList()
                    .listStyle(.plain)
                    .alert("Alert!", isPresented: $controller.showDeleteMessageAlert) {
                        Button("Cancel", role: .cancel) {}
                        Button("Delete", role: .destructive) {
                            Task {
                                guard let messForDeletion = controller.selectedMessForDeletion else { return }
                                addressStore.selectedMessage = nil
                                await addressStore.deleteMessage(message: messForDeletion)
                            }
                        }
                    } message: {
                        Text("Are you sure you want to delete this message?")
                    }
            }
        }
        .navigationTitle(address.ifNameElseAddress.extractUsername())
        .searchable(text: $controller.searchText)
#if os(iOS)
        .refreshable {
            Task { await addressStore.fetchMessages(for: address) }
        }
        .toolbar(content: {
            if !addressStore.showUnifiedInbox {
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
    private func MessagesList() -> some View {
        @Bindable var addressStore = addressStore
        let selectionBinding = Binding(
            get: { addressStore.selectedMessage },
            set: { newVal in
                DispatchQueue.main.async {
                    addressStore.selectedMessage = newVal
                }
            }
        )
        Group {
#if os(iOS)
            List(filteredMessages) { message in
                MessageItemView(message: message)
            }
#elseif os(macOS)
            List(filteredMessages, selection: selectionBinding) { message in
                NavigationLink(value: message) {
                    MessageItemView(message: message)
                }
            }
#endif
        }
    }
}
