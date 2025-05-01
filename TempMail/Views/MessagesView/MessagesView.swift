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
    
    let account: Account?
    
    var messages: [Message] {
        return account?.messagesStore?.messages ?? []
    }
    
    var body: some View {
        Group {
            if let safeAccount = account {
                VStack {
                    if messages.isEmpty {
                        VStack {
                            Spacer()
                            Text("No messages")
                            Spacer()
                        }
                    } else {
                        List(selection: $accountsController.selectedMessage) {
                            ForEach(messages) { message in
                                NavigationLink {
                                    //                            Text("message.data.")
                                    MessageDetailView(message: message, account: safeAccount)
                                } label: {
                                    MessageItemView(
                                        controller: controller, message: message,
                                        account: safeAccount
                                    )
                                    .environmentObject(controller)
                                }
                            }
                            .onDelete { indexSet in
                                accountsController.deleteMessage(indexSet: indexSet, account: safeAccount)
                            }
                        }
                        .listStyle(.plain)
                        .searchable(text: $controller.searchText)
                        .alert("Alert!", isPresented: $controller.showDeleteMessageAlert) {
                            Button("Cancel", role: .cancel) {
                                
                            }
                            Button("Delete", role: .destructive) {
                                guard let messForDeletion = controller.selectedMessForDeletion else { return }
                                accountsController.deleteMessage(message: messForDeletion, account: safeAccount)
                                controller.selectedMessForDeletion = nil
                            }
                        } message: {
                            Text("Are you sure you want to delete this account?")
                        }
                    }
                }
                .navigationTitle(safeAccount.name ?? safeAccount.address.extractUsername())
            } else {
                Text("Address not selected")
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button {
                    accountsController.fetchMessages(for: account!)
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise.circle")
                }
                .disabled(account == nil)
                Button {
                    addressesViewModel.selectedAccForInfoSheet = account!
                    addressesViewModel.isAccountInfoSheetOpen = true
                } label: {
                    Label("Account Info", systemImage: "info.square")
                }
                .disabled(account == nil)
                Button {
                    addressesViewModel.selectedAccForEditSheet = account!
                    addressesViewModel.isEditAccountSheetOpen = true
                } label: {
                    Label("Edit", systemImage: "pencil.circle")
                }
                .disabled(account == nil)
                Button {
                } label: {
                    Label("Archive", systemImage: "archivebox")
                }
                .disabled(true)
                Button(role: .destructive) {
                    addressesViewModel.showDeleteAccountAlert = true
                    addressesViewModel.selectedAccForDeletion = account!
                    //                    dataController.deleteAccount(account: account)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .disabled(account == nil)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AccountsController.shared)
}
