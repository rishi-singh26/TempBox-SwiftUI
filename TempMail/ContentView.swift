//
//  ContentView.swift
//  TempMail
//
//  Created by Rishi Singh on 01/05/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject private var accountsController: AccountsController
    @EnvironmentObject private var addressesViewModel: AddressesViewModel
    
    var body: some View {
#if os(iOS)
        NavigationView {
            AddressesView()
        }
#elseif os(macOS)
        NavigationSplitView {
            NewAddressBtn()
            AddressesView()
            Text("Powered by [mail.tm](https://www.mail.tm)")
                .font(.footnote)
        } content: {
            Group {
                if let safeAccount = accountsController.selectedAccount {
                    MessagesView(account: safeAccount)
                } else {
                    Text("Address not selected")
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    Button {
                        accountsController.fetchMessages(for: accountsController.selectedAccount!)
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise.circle")
                    }
                    .disabled(accountsController.selectedAccount == nil)
                    Button {
                        addressesViewModel.selectedAccForInfoSheet = accountsController.selectedAccount!
                        addressesViewModel.isAccountInfoSheetOpen = true
                    } label: {
                        Label("Account Info", systemImage: "info.square")
                    }
                    .disabled(accountsController.selectedAccount == nil)
                    Button {
                        addressesViewModel.selectedAccForEditSheet = accountsController.selectedAccount!
                        addressesViewModel.isEditAccountSheetOpen = true
                    } label: {
                        Label("Edit", systemImage: "pencil.circle")
                    }
                    .disabled(accountsController.selectedAccount == nil)
                    Button {
                    } label: {
                        Label("Archive", systemImage: "archivebox")
                    }
                    .disabled(true)
                    Button(role: .destructive) {
                        addressesViewModel.showDeleteAccountAlert = true
                        addressesViewModel.selectedAccForDeletion = accountsController.selectedAccount!
                        //                    dataController.deleteAccount(account: account)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .disabled(accountsController.selectedAccount == nil)
                }
            }
        } detail: {
            if let safeMessage = accountsController.selectedMessage, let safeAccount = accountsController.selectedAccount {
                MessageDetailView(message: safeMessage, account: safeAccount)
            } else {
                Text("No message selected")
            }
        }
        
#endif
    }
}

struct NewAddressBtn: View {
    @EnvironmentObject private var addressesViewModel: AddressesViewModel
    
    var body: some View {
        Button(action: addressesViewModel.openNewAddressSheet, label: {
            VStack(alignment: .leading) {
                HStack {
                    Text("New Address")
                        .foregroundStyle(.primary)
                        .padding(.leading, 4)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.primary)
                }
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(6)
            }
        })
        .padding(.horizontal)
        .padding(.vertical, 5)
        .buttonStyle(.plain)
        .keyboardShortcut(.init("a", modifiers: [.command]))
    }
}

#Preview {
    ContentView()
        .environmentObject(AccountsController.shared)
}
