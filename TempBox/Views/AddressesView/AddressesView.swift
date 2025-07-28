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
                    ActionButton()
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


#if os(iOS)
struct ActionButton: View {
    @EnvironmentObject private var addressesViewModel: AddressesViewModel
    @EnvironmentObject private var appController: AppController
    @Environment(\.colorScheme) var colorScheme
    @State private var actionMenuHaptic: Bool = false
    
    @State private var folderName: String = ""
    
    var body: some View {
        let accentColor = appController.accentColor(colorScheme: colorScheme)
        MorphingButton(backgroundColor: .primary, showExpandedContent: $addressesViewModel.showExpandedContent) {
            Image(systemName: "plus")
                .fontWeight(.semibold)
                .foregroundStyle(accentColor)
                .frame(width: 45, height: 45)
                .background(.thinMaterial)
                .clipShape(.circle)
                .contentShape(.circle)
        } content: {
            VStack(alignment: .leading, spacing: 12) {
                RowView("plus.circle", "New Address", "Create or Login to new Address")
                RowView("folder.badge.plus", "New Folder", "Create new Folder")
                RowView("bolt", "Quick Address", "Create an address and copy")
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 10)
        } expandedContent: {
            VStack {
                HStack {
                    Text("Expanded Content")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer(minLength: 0)
                    
                    Button {
                        actionMenuHaptic.toggle()
                        addressesViewModel.showExpandedContent = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                }
                .padding(10)
                TextField("Text", text: $folderName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 6)
                Spacer()
            }
            .padding(15)
        }
        .sensoryFeedback(.impact, trigger: actionMenuHaptic)
    }
    
    @ViewBuilder
    private func RowView(_ image: String, _ title: String, _ desc: String) -> some View {
        HStack(spacing: 18) {
            Image(systemName: image)
                .foregroundStyle(.primary)
                .frame(width: 45, height: 45)
                .background(.background, in: .circle)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text(desc)
                    .font(.callout)
                    .foregroundStyle(.gray)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .contentShape(.rect)
        .onTapGesture {
            actionMenuHaptic.toggle()
            addressesViewModel.showExpandedContent.toggle()
        }
    }
}
#endif
