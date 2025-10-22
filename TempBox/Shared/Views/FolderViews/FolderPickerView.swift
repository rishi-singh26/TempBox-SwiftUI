//
//  FolderPickerView.swift
//  TempBox
//
//  Created by Rishi Singh on 28/07/25.
//

import SwiftUI
import SwiftData

struct FolderPickerView: View {
    @Binding var selectedFolder: Folder?
    @Binding var showAddFolder: Bool
    
    @Query(sort: [SortDescriptor(\Folder.name, order: .forward)])
    private var folders: [Folder]
    
    var body: some View {
#if os(iOS)
        NavigationLink {
            FolderPicker()
        } label: {
            HStack {
                Label("Select Folder", systemImage: "folder")
                Spacer()
                Text(selectedFolder?.name ?? "No Folder")
                    .foregroundStyle(.tint)
            }
        }
#elseif os(macOS)
        HStack {
            Picker("Select Folder", selection: $selectedFolder) {
                Text("No Folder").tag(nil as Folder?)
                ForEach(folders) { folder in
                    Text(folder.name).tag(folder)
                }
            }
            
            Spacer()
            
            Button {
                showAddFolder = true
            } label: {
                Image(systemName: "folder.badge.plus")
            }
            .help("Create new folder")
        }
        .frame(maxWidth: .infinity)
#endif
    }
    
#if os(iOS)
    @ViewBuilder
    private func FolderPicker() -> some View {
        List {
            Section {
                Button {
                    showAddFolder = true
                } label: {
                    HStack {
                        Label("New Folder", systemImage: "folder.badge.plus")
                        Spacer()
                        Image(systemName: "plus.circle")
                            .foregroundStyle(.gray)
                    }
                }
            }
            
            Section {
                Picker("Select Folder", selection: $selectedFolder) {
                    Label("No Folder", systemImage: "folder.badge.minus")
                        .tag(nil as Folder?)
                    ForEach(folders) { folder in
                        Label(folder.name, systemImage: folder.id.contains(KQuickAddressesFolderIdPrefix) ? "bolt.square" : "folder")
                            .tag(folder)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            } header: {
                HStack {
                    Text("Select Folder")
                    Spacer()
                    Button("Clear") {
                        selectedFolder = nil
                    }
                    .controlSize(.small)
                }
            }
        }
        .navigationTitle("Select Folder")
        .navigationBarTitleDisplayMode(.inline)
    }
#endif
}
