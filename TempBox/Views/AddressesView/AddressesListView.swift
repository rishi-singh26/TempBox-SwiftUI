//
//  AddressesListView.swift
//  TempBox
//
//  Created by Rishi Singh on 27/07/25.
//

import SwiftUI

struct AddressesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    @EnvironmentObject private var addressesController: AddressesController
    @EnvironmentObject private var addressesViewModel: AddressesViewModel
    @EnvironmentObject private var appController: AppController

    var folders: [Folder]
    var allAddresses: [Address]

    // MARK: - Grouping Addresses
    private var addressesByFolder: [String: [Address]] {
        Dictionary(grouping: allAddresses.filter { $0.folder != nil }, by: { $0.folder!.id })
    }

    private var addressesWithoutFolder: [Address] {
        allAddresses.filter { $0.folder == nil }
    }

    var body: some View {
        #if os(iOS)
        if DeviceType.isIphone {
            iPhoneList()
        } else {
            IPadAndMacList()
        }
        #elseif os(macOS)
        IPadAndMacList()
        #endif
    }

    // MARK: - UI Builders
    @ViewBuilder
    private func iPhoneList() -> some View {
        let emptyAddress = Address.empty(id: KUnifiedInboxId)
        
        List {
            Section { UnifiedInboxButton(emptyAddress) }
            
            if !folders.isEmpty {
                Section("Folders", isExpanded: $addressesViewModel.foldersSectionExpanded) {
                    ForEach(folders) { folder in
                        let folderAddresses = addressesByFolder[folder.id] ?? []
                        DisclosureGroup {
                            ForEach(folderAddresses) { address in
                                AddressItemView(address: address)
                            }
                        } label: {
                            FolderTile(folder: folder)
                        }
                        
                    }
                }
                .headerProminence(.increased)
            }
            
            if !addressesWithoutFolder.isEmpty {
                Section("Others", isExpanded: $addressesViewModel.noFoldersSectionExpanded) {
                    ForEach(addressesWithoutFolder) { address in
                        AddressItemView(address: address)
                    }
                }
                .headerProminence(.increased)
            }
        }
        .listStyle(.sidebar)
    }
    
    @ViewBuilder
    private func IPadAndMacList() -> some View {
        let emptyAddress = Address.empty(id: KUnifiedInboxId)
        let selectionBinding = Binding<Address?>(
            get: {
                addressesController.showUnifiedInbox ? emptyAddress : addressesController.selectedAddress
            },
            set: { newVal in
                DispatchQueue.main.async {
                    addressesController.selectedAddress = newVal
                    addressesController.showUnifiedInbox = newVal?.id == KUnifiedInboxId
                }
            }
        )
        
        List(selection: selectionBinding) {
            NavigationLink(value: emptyAddress) {
                UnifiedInboxLable()
            }

            if !folders.isEmpty {
                Section("Folders", isExpanded: $addressesViewModel.foldersSectionExpanded) {
                    ForEach(folders) { folder in
                        let folderAddresses = addressesByFolder[folder.id] ?? []
                        DisclosureGroup {
                            ForEach(folderAddresses) { address in
                                NavigationLink(value: address) {
                                    AddressItemView(address: address)
                                }
                            }
                        } label: {
                            FolderTile(folder: folder)
                        }
                    }
                }
                .headerProminence(.increased)
            }
            
            if !addressesWithoutFolder.isEmpty {
                Section("Others", isExpanded: $addressesViewModel.noFoldersSectionExpanded) {
                    ForEach(addressesWithoutFolder) { address in
                        NavigationLink(value: address) {
                            AddressItemView(address: address)
                        }
                    }
                }
                .headerProminence(.increased)
            }
        }
    }

    @ViewBuilder
    private func UnifiedInboxButton(_ emptyAddress: Address) -> some View {
        Button {
            addressesController.selectedAddress = emptyAddress
            addressesController.showUnifiedInbox = true
            appController.path.append(emptyAddress)
        } label: {
            UnifiedInboxLable()
        }
    }
    
    @ViewBuilder
    private func UnifiedInboxLable() -> some View {
        HStack {
            Label("All Inboxes", systemImage: "tray.2")
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.bold())
                .foregroundColor(.secondary)
                .padding(.leading, 4)
        }
    }
    
    @ViewBuilder
    private func FolderTile(folder: Folder) -> some View {
        Label {
            Text(folder.name)
        } icon: {
            HStack(spacing: 5) {
                Text(String(folder.addresses?.count ?? 0))
                Image(systemName: folder.id.contains(KQuickAddressesFolderIdPrefix) ? "bolt.square" : "folder")
            }
        }
        .swipeActions {
            Button(role: .destructive) {
                deleteFolder(folder)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .contextMenu {
            Button(role: .destructive) {
                deleteFolder(folder)
            } label: {
                Label("Delete Folder", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Private functions
    private func deleteFolder(_ folder: Folder) {
        modelContext.delete(folder)
        try? modelContext.save()
    }
}
