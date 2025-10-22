//
//  ManageFoldersView.swift
//  TempBox
//
//  Created by Rishi Singh on 28/07/25.
//

import SwiftUI
import SwiftData

struct ManageFoldersView: View {
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: [SortDescriptor(\Folder.createdAt, order: .reverse)])
    private var folders: [Folder]
    
    var body: some View {
#if os(iOS)
        IOSView()
#elseif os(macOS)
        MacOSView()
#endif
    }
    
#if os(iOS)
    @ViewBuilder
    func IOSView() -> some View {
        List {
            if !folders.isEmpty {
                ForEach(folders, id: \.self) { folder in
                    DisclosureGroup {
                        IOSAddressesList(folder: folder)
                    } label: {
                        Label(folder.name, systemImage: folder.id.contains(KQuickAddressesFolderIdPrefix) ? "bolt.square" : "folder")
                            .swipeActions {
                                Button(role: .destructive) {
                                    deleteFolder(folder)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .help("Delete Folder")
                            }
                    }
                }
            } else {
                Text("No folders")
            }
        }
        .navigationTitle("Manage Folders")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func IOSAddressesList(folder: Folder) -> some View {
        Group {
            if let addresses: [Address] = folder.addresses {
                ForEach(addresses, id: \.self) { address in
                    Label(address.ifNameElseAddress, systemImage: "tray")
                        .swipeActions {
                            Button(role: .destructive) {
                                removeAddress(address, from: folder)
                            } label: {
                                Label("Remove", systemImage: "minus.circle")
                            }
                            .help("Remove address from folder")
                        }
                }
            }
        }
    }
#endif
    
#if os(macOS)
    @ViewBuilder
    func MacOSView() -> some View {
        List {
            if !folders.isEmpty {
                ForEach(folders, id: \.self) { (folder: Folder) in
                    DisclosureGroup(
                        content: {
                            MacAddressesList(folder: folder)
                        },
                        label: {
                            FolderTile(folder: folder)
                        }
                    )
                }
            } else {
                Text("No folders")
            }
        }
        .listStyle(.inset)
        .navigationTitle("Manage Folders")
    }
    
    private func FolderTile(folder: Folder) -> some View {
        HStack {
            Label(folder.name, systemImage: folder.id.contains(KQuickAddressesFolderIdPrefix) ? "bolt.square" : "folder")
            Spacer()
            Button {
                deleteFolder(folder)
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.gray)
            }
            .buttonStyle(.plain)
            .help("Permanently Delete Folder")
        }
        .padding([.trailing, .vertical], 5)
    }
    
    private func MacAddressesList(folder: Folder) -> some View {
        Group {
            if let addresses: [Address] = folder.addresses, !addresses.isEmpty {
                ForEach(addresses, id: \.self) { address in
                    HStack {
                        Label(address.ifNameElseAddress, systemImage: "tray")
                        Spacer()
                        Button {
                            removeAddress(address, from: folder)
                        } label: {
                            Image(systemName: "minus.circle")
                                .foregroundStyle(.gray)
                        }
                        .buttonStyle(.plain)
                        .help("Remove address from folder")
                    }
                    .padding([.trailing, .vertical], 5)
                }
            }
            else {
                Text("No addresses")
                    .foregroundStyle(.secondary)
            }
        }
    }
#endif
    
    private func deleteFolder(_ folder: Folder) {
        modelContext.delete(folder)
        try? modelContext.save()
    }
    
    private func removeAddress(_ address: Address, from folder: Folder) {
        folder.addresses?.removeAll { $0.id == address.id}
        try? modelContext.save()
    }
}
