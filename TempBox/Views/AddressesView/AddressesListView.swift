//
//  AddressesListView.swift
//  TempBox
//
//  Created by Rishi Singh on 27/07/25.
//

import SwiftUI
import SwiftData

struct AddressesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    @EnvironmentObject private var addressesController: AddressesController
    @EnvironmentObject private var addressesViewModel: AddressesViewModel
    @EnvironmentObject private var appController: AppController

    @Query(sort: [SortDescriptor(\Folder.createdAt, order: .reverse)])
    private var folders: [Folder]
    
    // Dynamic query that includes search filtering so no separate computed filter is needed.
    @Query var addressesWithoutFolder: [Address]
    
    init(searchQuery q: String) {
        // Configure the query each render to reflect current search text
        self._addressesWithoutFolder = Query(
            filter: #Predicate<Address> { addr in
                // Only non-archived
                !addr.isArchived &&
                // Must belong to the passed folder
                addr.folder?.id == nil &&
                // Search filter (empty query allows all)
                (
                    q.isEmpty ||
                    addr.name?.localizedStandardContains(q) ?? false ||
                    addr.address.localizedStandardContains(q)
                )
            },
            sort: [SortDescriptor(\Address.createdAt, order: .reverse)]
        )
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
                        DisclosureGroup {
                            FolderAddressesView(searchQuery: addressesViewModel.searchText, folder: folder)
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
                // AddressesController is @MainActor; update on main actor without DispatchQueue.
                Task { @MainActor in
                    addressesController.selectedAddress = newVal
                    addressesController.showUnifiedInbox = newVal?.id == KUnifiedInboxId
                }
            }
        )
        
        List(selection: selectionBinding) {
            NavigationLink(value: emptyAddress) {
                UnifiedInboxLabel()
            }

            if !folders.isEmpty {
                Section("Folders", isExpanded: $addressesViewModel.foldersSectionExpanded) {
                    ForEach(folders) { folder in
                        DisclosureGroup {
                            FolderAddressesView(searchQuery: addressesViewModel.searchText, folder: folder)
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
            UnifiedInboxLabel()
        }
    }
    
    @ViewBuilder
    private func UnifiedInboxLabel() -> some View {
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
        Label(folder.name, systemImage: folder.id.contains(KQuickAddressesFolderIdPrefix) ? "bolt.square" : "folder")
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    deleteFolder(folder)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .swipeActions(edge: .leading) {
                Button {
                    folderInfo(folder)
                } label: {
                    Label("Info", systemImage: "info.square")
                }
                .tint(.yellow)
            }
            .contextMenu {
                Button {
                    folderInfo(folder)
                } label: {
                    Label("Info", systemImage: "info.square")
                }
                Divider()
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
    
    private func folderInfo(_ folder: Folder) {
        addressesViewModel.selectedFolderForInfoSheet = folder
        addressesViewModel.isFolderInfoSheetOpen = true
    }
}


private struct FolderAddressesView: View {
    var searchQuery: String = ""
    var folder: Folder
    
    @Query var addresses: [Address]
    
    init(searchQuery: String = "", folder: Folder) {
        self.searchQuery = searchQuery
        self.folder = folder
        
        let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let folderId = folder.id
        
        self._addresses = Query(
            filter: #Predicate<Address> { addr in
                // Only non-archived
                !addr.isArchived &&
                // Must belong to the passed folder
                addr.folder?.id == folderId &&
                // Search filter (empty query allows all)
                (
                    q.isEmpty ||
                    addr.name?.localizedStandardContains(q) ?? false ||
                    addr.address.localizedStandardContains(q)
                )
            },
            sort: [SortDescriptor(\Address.createdAt, order: .reverse)]
        )
    }
    
    var body: some View {
        ForEach(addresses) { address in
            NavigationLink(value: address) {
                AddressItemView(address: address)
            }
        }
    }
}

