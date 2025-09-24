//
//  AddressesView.swift
//  TempBox
//
//  Created by Rishi Singh on 01/05/25.
//

import SwiftUI

struct AddressesView: View {
    @EnvironmentObject private var addressesController: AddressesController
    @EnvironmentObject private var addressesViewModel: AddressesViewModel
    @EnvironmentObject private var appController: AppController
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let accentColor = appController.accentColor(colorScheme: colorScheme)
        
        AddressesListView(searchQuery: addressesViewModel.searchText)
#if os(iOS)
        // Ensure the toolbar itself only exists on iOS 18+
            .modifier(IOS18BottomToolbarModifier())
            .toolbar(content: SettingsButton)
            .sheet(isPresented: $addressesViewModel.isQuickAddressSheetOpen) {
                QuickAddressView()
                    .sheetAppearanceSetup(tint: accentColor)
            }
#endif
            .sheet(isPresented: $addressesViewModel.isNewAddressSheetOpen) {
                AddAddressView()
                    .sheetAppearanceSetup(tint: accentColor)
            }
            .sheet(isPresented: $addressesViewModel.isNewFolderSheetOpen) {
                NewFolderView()
                    .sheetAppearanceSetup(tint: accentColor)
            }
            .navigationTitle("TempBox")
            .navigationSubtitleIfAvailable("Powered by mail.tm")
            .searchable(text: $addressesViewModel.searchText)
            .refreshable {
                Task {
                    await addressesController.fetchAddresses()
                }
            }
            .sheet(isPresented: $addressesViewModel.isAddressInfoSheetOpen) {
                if let selected = addressesViewModel.selectedAddForInfoSheet {
                    AddressInfoView(address: selected)
                        .sheetAppearanceSetup(tint: accentColor)
                }
            }
            .sheet(isPresented: $addressesViewModel.isFolderInfoSheetOpen) {
                if let selected = addressesViewModel.selectedFolderForInfoSheet {
                    FolderInfoView(folder: selected)
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
    
#if os(iOS)
    @ToolbarContentBuilder
    private func SettingsButton() -> some ToolbarContent {
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
}

// A small helper modifier to apply the bottom toolbar only on iOS 18+
// Keeps the main view body clean and ensures the toolbar is absent on earlier iOS.
#if os(iOS)
private struct IOS18BottomToolbarModifier: ViewModifier {
    @EnvironmentObject private var addressesViewModel: AddressesViewModel
    @EnvironmentObject private var appController: AppController

    @Environment(\.colorScheme) var colorScheme
    
    @ViewBuilder
    func body(content: Content) -> some View {
        let accentColor = appController.accentColor(colorScheme: colorScheme)
        if #available(iOS 26.0, *) {
            content.toolbar {
                DefaultToolbarItem(kind: .search, placement: .bottomBar)
                
                // Add flexible space so the search doesn’t crowd the button
                ToolbarSpacer(.flexible, placement: .bottomBar)
                
                // Your button in the bottom bar
                ToolbarItem(placement: .bottomBar) {
                    Menu("Add", systemImage: "plus") {
                        Button("New Address", systemImage: "plus.circle", action: addressesViewModel.openNewAddressSheet)
                        Button("New Folder", systemImage: "folder.badge.plus", action: addressesViewModel.openNewFolderSheet)
                        Button("Quick Address", systemImage: "bolt", action: addressesViewModel.openQuickAddressSheet)
                    }
                    .tint(accentColor)
                    .menuOrder(.fixed)
                    .help("Create new address or login to an address")
                }
            }
        } else {
            content.toolbar {
                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        Menu {
                            Button("New Address", systemImage: "plus.circle", action: addressesViewModel.openNewAddressSheet)
                            Button("New Folder", systemImage: "folder.badge.plus", action: addressesViewModel.openNewFolderSheet)
                            Button("Quick Address", systemImage: "bolt", action: addressesViewModel.openQuickAddressSheet)
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("New Address")
                                    .fontWeight(.semibold)
                            }
                        }
                        .tint(accentColor)
                        .menuOrder(.fixed)
                        .help("Create new address or login to an address")
                        Spacer()
                        MarkdownLinkText(markdownText: "Powered by [mail.tm](https://www.mail.tm)")
                            .font(.footnote)
                    }
                }
            }
        }
    }
}
#endif
