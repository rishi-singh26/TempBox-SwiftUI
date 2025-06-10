//
//  MessagesView.swift
//  TempMail
//
//  Created by Rishi Singh on 01/05/25.
//

import SwiftUI

struct MessagesView: View {
    @EnvironmentObject private var addressesController: AddressesController
    @EnvironmentObject private var addressesViewModel: AddressesViewModel
    @StateObject private var controller = MessagesViewModel()
    
    var address: Address
    
    var messages: [Message] {
        let safeMessages = address.messagesStore?.messages ?? []
        if safeMessages.isEmpty {
            return safeMessages
        }
        if controller.searchText.isEmpty {
            return safeMessages
        } else {
            let searchQuery = controller.searchText.lowercased()
            return safeMessages.filter { message in
                let subMatches = message.subject.lowercased().contains(searchQuery)
                let fromMatches = message.fromAddress.contains(searchQuery)
                return subMatches || fromMatches
            }
        }
    }
    
    var body: some View {
        VStack {
            if messages.isEmpty {
                VStack {
                    Spacer()
                    Text("No messages")
                    Spacer()
                }
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
                            }
                        }
                    } message: {
                        Text("Are you sure you want to delete this message?")
                    }
            }
        }
        .searchable(text: $controller.searchText)
        .navigationTitle(address.name ?? address.address.extractUsername())
#if os(iOS)
        .toolbar(content: {
            ToolbarItem {
                Button("Message Information", systemImage: "info.circle") {
                    addressesViewModel.selectedAddForInfoSheet = address
                    addressesViewModel.isAddressInfoSheetOpen = true
                }
            }
        })
#endif
    }
    
    @ViewBuilder
    func MessagesList(address: Address) -> some View {
        Group {
#if os(iOS)
            List(messages, selection: Binding(get: {
                addressesController.selectedMessage
            }, set: { newVal in
                DispatchQueue.main.async {
                    addressesController.selectedMessage = newVal
                }
            })) { message in
                NavigationLink {
                    MessageDetailView(message: message, address: address)
                }label: {
                    MessageItemView(
                        controller: controller, message: message,
                        address: address
                    )
                    .environmentObject(controller)
                }
            }
#elseif os(macOS)
            List(messages, selection: Binding(get: {
                addressesController.selectedMessage
            }, set: { newVal in
                DispatchQueue.main.async {
                    addressesController.selectedMessage = newVal
                }
            })) { message in
                NavigationLink(value: message) {
                    MessageItemView(
                        controller: controller, message: message,
                        address: address
                    )
                    .environmentObject(controller)
                }
            }
#endif
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AddressesController.shared)
        .environmentObject(AddressesViewModel.shared)
}
