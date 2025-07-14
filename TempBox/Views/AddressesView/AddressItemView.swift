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
    @EnvironmentObject private var appController: AppController
    
    private var isMessagesFetching: Bool {
        addressesController.messageStore[address.id]?.isFetching ?? false
    }
    
    private var isMessagesFetchingFailed: Bool {
        addressesController.messageStore[address.id]?.error != nil
    }
    
    private var unreadMessagesCount: Int {
        addressesController.messageStore[address.id]?.unreadMessagesCount ?? 0
    }
    
    var body: some View {
        Group {
#if os(iOS)
            if DeviceType.isIphone {
                Button {
                    addressesController.selectedAddress = address
                    if DeviceType.isIphone {
                        appController.path.append(address)
                    } else {
                        appController.path = NavigationPath()
                    }
                } label: {
                    AddressTileBuilder()
                }
            } else {
                AddressTileBuilder()
            }
#elseif os(macOS)
            AddressTileBuilder()
#endif
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
    private func AddressTileBuilder() -> some View {
        HStack {
            HStack {
                Image(systemName: "tray")
                    .foregroundColor(.accentColor)
                HStack {
                    Text(address.ifNameElseAddress.extractUsername())
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
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
    }
    
    @ViewBuilder
    private func BuildAddrInfoButton(addTint: Bool = true) -> some View {
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
    private func BuildRefreshButton(addTint: Bool = true) -> some View {
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
    private func BuildEditButton(addTint: Bool = true) -> some View {
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
    private func BuildDeleteButton(addTint: Bool = true) -> some View {
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
    private func BuildArchiveButton(addTint: Bool = true) -> some View {
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
