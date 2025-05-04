//
//  MessagesView.swift
//  TempMail
//
//  Created by Rishi Singh on 01/05/25.
//

import SwiftUI

struct MessagesView: View {
    @EnvironmentObject private var accountsController: AccountsController
    @EnvironmentObject private var addressesViewModel: AddressesViewModel
    @StateObject private var controller = MessagesViewModel()
    
    let accountId: String
    
    var account: Account? {
        accountsController.getAccount(withID: accountId)
    }
    
    var messages: [Message] {
        let safeMessages = accountsController.getAccount(withID: accountId)?.messagesStore?.messages ?? []
        if safeMessages.isEmpty {
            return safeMessages
        }
        if controller.searchText.isEmpty {
            return safeMessages
        } else {
            let searchQuery = controller.searchText.lowercased()
            return safeMessages.filter { message in
                let subMatches = message.data.subject.lowercased().contains(searchQuery)
                let fromMatches = message.fromAddress.contains(searchQuery)
                return subMatches || fromMatches
            }
        }
    }
    
    var body: some View {
        if let account = account {
            VStack {
                if messages.isEmpty {
                    VStack {
                        Spacer()
                        Text("No messages")
                        Spacer()
                    }
                } else {
                    MessagesList(account: account)
                        .listStyle(.plain)
                        .alert("Alert!", isPresented: $controller.showDeleteMessageAlert) {
                            Button("Cancel", role: .cancel) {
                                
                            }
                            Button("Delete", role: .destructive) {
                                guard let messForDeletion = controller.selectedMessForDeletion else { return }
                                accountsController.deleteMessage(message: messForDeletion, account: account)
                                controller.selectedMessForDeletion = nil
                            }
                        } message: {
                            Text("Are you sure you want to delete this account?")
                        }
                }
            }
            .searchable(text: $controller.searchText)
            .navigationTitle(account.name ?? account.address.extractUsername())
#if os(iOS)
            .toolbar(content: {
                ToolbarItem {
                    Button("Message Information", systemImage: "info.circle") {
                        addressesViewModel.selectedAccForInfoSheet = account
                        addressesViewModel.isAccountInfoSheetOpen = true
                    }
                }
            })
#endif
        } else {
            Text("Selected Address not available")
        }
    }
    
    @ViewBuilder
    func MessagesList(account: Account) -> some View {
        Group {
#if os(iOS)
            List(messages, selection: Binding(get: {
                accountsController.selectedMessage
            }, set: { newVal in
                DispatchQueue.main.async {
                    accountsController.selectedMessage = newVal
                }
            })) { message in
                NavigationLink {
                    MessageDetailView(message: message, account: account)
                }label: {
                    MessageItemView(
                        controller: controller, message: message,
                        account: account
                    )
                    .environmentObject(controller)
                }
            }
#elseif os(macOS)
            List(messages, selection: Binding(get: {
                accountsController.selectedMessage
            }, set: { newVal in
                DispatchQueue.main.async {
                    accountsController.selectedMessage = newVal
                }
            })) { message in
                NavigationLink(value: message) {
                    MessageItemView(
                        controller: controller, message: message,
                        account: account
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
        .environmentObject(AccountsController.shared)
        .environmentObject(AddressesViewModel.shared)
}
