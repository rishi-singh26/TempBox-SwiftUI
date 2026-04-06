//
//  AddressItemView.swift
//  TempBox
//
//  Created by Rishi Singh on 01/05/25.
//

import SwiftUI

struct AddressItemView: View {
    let address: Address
    @Environment(AddressStore.self) private var addressStore
    @Environment(AddressesViewModel.self) private var addressesViewModel
    @Environment(AppStore.self) private var appStore

    @Environment(\.colorScheme) private var colorScheme

    private var isMessagesFetching: Bool {
        addressStore.messageStore[address.id]?.isFetching ?? false
    }

    private var isMessagesFetchingFailed: Bool {
        addressStore.messageStore[address.id]?.error != nil
    }

    private var unreadMessagesCount: Int {
        (address.messages ?? []).filter { !$0.seen }.count
    }

    var body: some View {
        Group {
#if os(iOS)
            if DeviceType.isIphone {
                Button {
                    addressStore.selectedAddress = address
                    addressStore.showUnifiedInbox = address.id == KUnifiedInboxId
                    appStore.path.append(address)
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
        }
        .swipeActions(edge: .trailing) {
            BuildDeleteButton()
            BuildArchiveButton()
        }
        .contextMenu(menuItems: {
            BuildRefreshButton(addTint: false)
            BuildAddrInfoButton(addTint: false)
            Divider()
            BuildArchiveButton(addTint: false)
            BuildDeleteButton(addTint: false)
        })
    }

    @ViewBuilder
    private func AddressTileBuilder() -> some View {
        HStack {
            Label {
                Text(address.ifNameElseAddress.extractUsername())
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
            } icon: {
                Image(systemName: "tray")
            }
            Spacer()
            if !address.isArchived && !address.isDeleted {
                if isMessagesFetching {
                    ProgressView()
                        .controlSize(.mini)
                } else if isMessagesFetchingFailed {
                    Image(systemName: "exclamationmark.triangle.fill")
                } else if unreadMessagesCount != 0 {
                    Text("\(unreadMessagesCount)")
                        .foregroundColor(.secondary)
                }
            }
            Image(systemName: "chevron.right")
                .font(.footnote.bold())
                .foregroundColor(.secondary)
                .padding(.leading, 4)
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
                await addressStore.fetchMessages(for: address)
            }
        } label: {
            Label("Refresh", systemImage: "arrow.clockwise.circle")
        }
        .help("Refresh address inbox")
        .tint(addTint ? .blue : nil)
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
        .tint(.red)
    }

    @ViewBuilder
    private func BuildArchiveButton(addTint: Bool = true) -> some View {
        Button {
            Task {
                await addressStore.toggleArchiveStatus(address)
            }
        } label: {
            Label("Archive", systemImage: "archivebox")
        }
        .help("Archive address")
        .tint(addTint ? .indigo : nil)
    }
}
