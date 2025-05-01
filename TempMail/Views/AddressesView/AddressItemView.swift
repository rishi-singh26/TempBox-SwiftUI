//
//  AddressItemView.swift
//  TempMail
//
//  Created by Rishi Singh on 01/05/25.
//

import SwiftUI

struct AddressItemView: View {
    let account: Account
    @EnvironmentObject private var accountsController: AccountsController
    @EnvironmentObject private var addressesViewModel: AddressesViewModel
    
    var isMessagesFetching: Bool {
        account.messagesStore?.isFetching ?? false
    }
    
    var isMessagesFetchingFailed: Bool {
        account.messagesStore?.error != nil
    }
    
    var unreadMessagesCount: Int {
        account.messagesStore?.unreadMessagesCount ?? 0
    }
    
    var body: some View {
        HStack {
            Image(systemName: "tray")
                .foregroundColor(.accentColor)
            HStack {
                Text(account.name ?? account.address)
//                VStack(alignment: .leading) {
//                    Text(account.accountName ?? account.address ?? "No address")
//                    if account.accountName != nil {
//                        Text(account.address ?? "No address")
//                            .foregroundColor(.secondary)
//                    }
//                }
                Spacer()
                if !account.isDisabled && !account.isDeleted {
                    if isMessagesFetching {
                        ProgressView()
                            .controlSize(.small)
                    } else if isMessagesFetchingFailed {
                        Image(systemName: "exclamationmark.triangle.fill")
                    } else if unreadMessagesCount != 0 {
                        Text("\(unreadMessagesCount)")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
            .swipeActions(edge: .leading) {
                Button {
                    addressesViewModel.selectedAccForInfoSheet = account
                    addressesViewModel.isAccountInfoSheetOpen = true
                } label: {
                    Label("Account Info", systemImage: "info.square")
                }
                .tint(.yellow)
                Button {
                    accountsController.fetchMessages(for: account)
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise.circle")
                }
                .tint(.blue)
                Button {
                    addressesViewModel.selectedAccForEditSheet = account
                    addressesViewModel.isEditAccountSheetOpen = true
                } label: {
                    Label("Edit", systemImage: "pencil.circle")
                }
                .tint(.orange)
            }
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    addressesViewModel.showDeleteAccountAlert = true
                    addressesViewModel.selectedAccForDeletion = account
//                    dataController.deleteAccount(account: account)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .tint(.red)
                Button {
                } label: {
                    Label("Archive", systemImage: "archivebox")
                }
                .tint(.indigo)
            }
            .contextMenu(menuItems: {
                Button {
                    accountsController.fetchMessages(for: account)
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise.circle")
                }
                Button {
                    addressesViewModel.selectedAccForInfoSheet = account
                    addressesViewModel.isAccountInfoSheetOpen = true
                } label: {
                    Label("Account Info", systemImage: "info.square")
                }
                Button {
                    addressesViewModel.selectedAccForEditSheet = account
                    addressesViewModel.isEditAccountSheetOpen = true
                } label: {
                    Label("Edit", systemImage: "pencil.circle")
                }
                Divider()
                Button {
                } label: {
                    Label("Archive", systemImage: "archivebox")
                }
                Button(role: .destructive) {
                    addressesViewModel.showDeleteAccountAlert = true
                    addressesViewModel.selectedAccForDeletion = account
//                    dataController.deleteAccount(account: account)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            })
    }
}


#Preview {
    ContentView()
            .environmentObject(AccountsController.shared)
            .environmentObject(AddressesViewModel.shared)
}
