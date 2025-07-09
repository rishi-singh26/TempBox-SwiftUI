//
//  AddressItemView.swift
//  TempBox
//
//  Created by Rishi Singh on 01/05/25.
//

import SwiftUI

struct AddressItemView: View {
    let address: Address
    @EnvironmentObject private var addressesController: AddressesController
    @EnvironmentObject private var addressesViewModel: AddressesViewModel
    
    var isMessagesFetching: Bool {
        addressesController.messageStore[address.id]?.isFetching ?? false
    }
    
    var isMessagesFetchingFailed: Bool {
        addressesController.messageStore[address.id]?.error != nil
    }
    
    var unreadMessagesCount: Int {
        addressesController.messageStore[address.id]?.unreadMessagesCount ?? 0
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
                if !address.isArchived && !address.isDeleted {
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
            BuildAddrInfoButton()
            BuildRefreshButton()
            BuildEditButton()
        }
        .swipeActions(edge: .trailing) {
            BuildDeleteButton()
            BuildArchiveButton()
        }
        .contextMenu(menuItems: {
            BuildRefreshButton(addTint: false)
            BuildAddrInfoButton(addTint: false)
            BuildEditButton(addTint: false)
            Divider()
            BuildArchiveButton(addTint: false)
            BuildDeleteButton(addTint: false)
        })
    }
    
    @ViewBuilder
    func BuildAddrInfoButton(addTint: Bool = true) -> some View {
        Button {
            addressesViewModel.selectedAddForInfoSheet = address
            addressesViewModel.isAddressInfoSheetOpen = true
        } label: {
            Label("Address Info", systemImage: "info.square")
        }
        .help("Address information")
        .tint(addTint ? .yellow : nil)
    }
    
    @ViewBuilder
    func BuildRefreshButton(addTint: Bool = true) -> some View {
        Button {
            Task {
                await addressesController.refreshMessages(for: address)
            }
        } label: {
            Label("Refresh", systemImage: "arrow.clockwise.circle")
        }
        .help("Refresh address inbox")
        .tint(addTint ? .blue : nil)
    }
    
    @ViewBuilder
    func BuildEditButton(addTint: Bool = true) -> some View {
        Button {
            addressesViewModel.selectedAddForEditSheet = address
            addressesViewModel.isEditAddressSheetOpen = true
        } label: {
            Label("Edit", systemImage: "pencil.circle")
        }
        .help("Edit address name")
        .tint(addTint ? .orange : nil)
    }
    
    @ViewBuilder
    func BuildDeleteButton(addTint: Bool = true) -> some View {
        Button {
            addressesViewModel.showDeleteAddressAlert = true
            addressesViewModel.selectedAddForDeletion = address
        } label: {
            Label("Delete", systemImage: "trash")
        }
        .help("Permanently delete address")
        .tint(addTint ? .red : nil)
    }
    
    @ViewBuilder
    func BuildArchiveButton(addTint: Bool = true) -> some View {
        Button {
            Task {
                await addressesController.toggleAddressStatus(address)
            }
        } label: {
            Label("Archive", systemImage: "archivebox")
        }
        .help("Archive address")
        .tint(addTint ? .indigo : nil)
    }
}


#Preview {
    ContentView()
            .environmentObject(AddressesController.shared)
            .environmentObject(AddressesViewModel.shared)
}
