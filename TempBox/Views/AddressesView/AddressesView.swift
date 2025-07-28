//
//  AddressesView.swift
//  TempBox
//
//  Created by Rishi Singh on 01/05/25.
//

import SwiftUI
import SwiftData

struct AddressesView: View {
    @EnvironmentObject private var addressesController: AddressesController
    @EnvironmentObject private var addressesViewModel: AddressesViewModel
    @EnvironmentObject private var appController: AppController

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext

    // Query all addresses
    @Query(filter: #Predicate<Address> { !$0.isArchived }, sort: [SortDescriptor(\Address.createdAt, order: .reverse)])
    private var allAddresses: [Address]
    
    @Query(sort: [SortDescriptor(\Folder.createdAt, order: .reverse)])
    private var folders: [Folder]

    // MARK: - Filtered Addresses
    private var filteredAddresses: [Address] {
        if addressesViewModel.searchText.isEmpty {
            return allAddresses
        } else {
            let query = addressesViewModel.searchText.lowercased()
            return allAddresses.filter { address in
                let nameMatches = address.name?.lowercased().contains(query) ?? false
                let addressMatches = address.address.lowercased().contains(query)
                return nameMatches || addressMatches
            }
        }
    }

    var body: some View {
        let accentColor = appController.accentColor(colorScheme: colorScheme)

        AddressesListView(folders: folders, allAddresses: filteredAddresses)
#if os(iOS)
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                HStack {
                    Menu {
                        Button("New Folder", systemImage: "folder.badge.plus") {
                            addressesViewModel.openNewFolderSheet()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("New Address")
                        }
                    } primaryAction: {
                        addressesViewModel.openNewAddressSheet()
                    }
                    .help("Create new address or login to an address")
                    Spacer()
                    MarkdownLinkText(markdownText: "Powered by [mail.tm](https://www.mail.tm)")
                        .font(.footnote)
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if DeviceType.isIphone {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                } else {
                    Button {
                        addressesViewModel.showSettingsSheet = true
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                }
            }
        }
#endif
        .navigationTitle("TempBox")
        .searchable(text: $addressesViewModel.searchText, placement: .sidebar)
        .listStyle(.sidebar)
        .refreshable {
            Task {
                await addressesController.fetchAddresses()
            }
        }
        .sheet(isPresented: $addressesViewModel.isNewAddressSheetOpen) {
            AddAddressView()
                .sheetAppearanceSetup(tint: accentColor)
        }
        .sheet(isPresented: $addressesViewModel.isNewFolderSheetOpen) {
            NewFolderView()
                .sheetAppearanceSetup(tint: accentColor)
        }
        .sheet(isPresented: $addressesViewModel.isAddressInfoSheetOpen) {
            if let selected = addressesViewModel.selectedAddForInfoSheet {
                AddressInfoView(address: selected)
                    .sheetAppearanceSetup(tint: accentColor)
            }
        }
        .sheet(isPresented: $addressesViewModel.showSettingsSheet) {
            SettingsView()
                .sheetAppearanceSetup(tint: accentColor)
        }
        .alert("Alert!", isPresented: $addressesViewModel.showDeleteAddressAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    guard let addressForDeletion = addressesViewModel.selectedAddForDeletion else { return }
                    await addressesController.deleteAddressFromServer(address: addressForDeletion)
                    addressesViewModel.selectedAddForDeletion = nil
                }
            }
        } message: {
            Text("Are you sure you want to delete this address? This action is irreversible. Once deleted, this address and the associated messages cannot be restored.")
        }
    }
}
