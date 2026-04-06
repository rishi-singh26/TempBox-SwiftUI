//
//  UnifiedMessagesView.swift
//  TempBox
//
//  Created by Rishi Singh on 26/07/25.
//

import SwiftUI
import SwiftData

struct UnifiedMessagesView: View {
    @Environment(AddressStore.self) private var addressStore
    @Environment(MessagesViewModel.self) private var controller

    @Query(sort: [SortDescriptor(\Message.createdAt, order: .reverse)])
    private var allMessages: [Message]

    private var filteredMessages: [Message] {
        if allMessages.isEmpty || controller.searchText.isEmpty { return allMessages }
        let searchQuery = controller.searchText.lowercased()
        return allMessages.filter { message in
            message.subject.lowercased().contains(searchQuery) ||
            message.fromAddress.contains(searchQuery)
        }
    }

    var body: some View {
        @Bindable var controller = controller

        Group {
            if filteredMessages.isEmpty {
                List { Text("No messages") }
                    .listStyle(.plain)
            } else {
                MessagesList()
                    .listStyle(.plain)
            }
        }
        .alert("Alert!", isPresented: $controller.showDeleteMessageAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    guard let messForDeletion = controller.selectedMessForDeletion else { return }
                    await addressStore.deleteMessage(message: messForDeletion)
                    controller.selectedMessForDeletion = nil
                    addressStore.selectedMessage = nil
                }
            }
        } message: {
            Text("Are you sure you want to delete this message?")
        }
        .navigationTitle("All Inboxes")
        .searchable(text: $controller.searchText)
#if os(iOS)
        .refreshable {
            Task { await addressStore.fetchAddresses() }
        }
#endif
    }

    @ViewBuilder
    private func MessagesList() -> some View {
        @Bindable var addressStore = addressStore
        let selectionBinding = Binding(
            get: { addressStore.selectedMessage },
            set: { newVal in
                Task { await addressStore.updateMessageSelection(message: newVal) }
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
