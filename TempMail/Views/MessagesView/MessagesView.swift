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
    
    let account: Account
    
    var messages: [Message] {
        return account.messagesStore?.messages ?? []
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
                MessagesList(account: account)
                .listStyle(.plain)
                .searchable(text: $controller.searchText)
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
        .navigationTitle(account.name ?? account.address.extractUsername())
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
}
