//
//  AddressItemView.swift
//  TempMail
//
//  Created by Rishi Singh on 01/05/25.
//

import SwiftUI

struct AddressItemView: View {
    let address: Address
    @EnvironmentObject private var addressesController: AddressesController
    @EnvironmentObject private var addressesViewModel: AddressesViewModel
    
    var isMessagesFetching: Bool {
        address.messagesStore?.isFetching ?? false
    }
    
    var isMessagesFetchingFailed: Bool {
        address.messagesStore?.error != nil
    }
    
    var unreadMessagesCount: Int {
        address.messagesStore?.unreadMessagesCount ?? 0
    }
    
    var addresName: String {
        address.name == nil || (address.name?.isEmpty ?? false) ? address.address : address.name!
    }
    
    var body: some View {
        HStack {
            Image(systemName: "tray")
                .foregroundColor(.accentColor)
            HStack {
                Text(addresName)
                Spacer()
                if !address.isDisabled && !address.isDeleted {
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
                    addressesViewModel.selectedAddForInfoSheet = address
                    addressesViewModel.isAddressInfoSheetOpen = true
                } label: {
                    Label("Address Info", systemImage: "info.square")
                }
                .tint(.yellow)
                Button {
                    Task {
                        await addressesController.fetchMessages(for: address)
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise.circle")
                }
                .tint(.blue)
                Button {
                    addressesViewModel.selectedAddForEditSheet = address
                    addressesViewModel.isEditAddressSheetOpen = true
                } label: {
                    Label("Edit", systemImage: "pencil.circle")
                }
                .tint(.orange)
            }
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    addressesViewModel.showDeleteAddressAlert = true
                    addressesViewModel.selectedAddForDeletion = address
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
                    Task {
                        await addressesController.fetchMessages(for: address)
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise.circle")
                }
                Button {
                    addressesViewModel.selectedAddForInfoSheet = address
                    addressesViewModel.isAddressInfoSheetOpen = true
                } label: {
                    Label("Address Info", systemImage: "info.circle")
                }
                Button {
                    addressesViewModel.selectedAddForEditSheet = address
                    addressesViewModel.isEditAddressSheetOpen = true
                } label: {
                    Label("Edit", systemImage: "pencil.circle")
                }
                Divider()
                Button {
                } label: {
                    Label("Archive", systemImage: "archivebox")
                }
                Button(role: .destructive) {
                    addressesViewModel.showDeleteAddressAlert = true
                    addressesViewModel.selectedAddForDeletion = address
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            })
    }
}


#Preview {
    ContentView()
            .environmentObject(AddressesController.shared)
            .environmentObject(AddressesViewModel.shared)
}
