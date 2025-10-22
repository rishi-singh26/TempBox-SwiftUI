//
//  FolderInfoView.swift
//  TempBox
//
//  Created by Rishi Singh on 23/09/25.
//

import SwiftUI
import SwiftData

struct FolderInfoView: View {
    @EnvironmentObject private var appController: AppController
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) var modelContext

    @State private var folderName = ""
    @State private var showAddFolderSheet: Bool = false
    @State private var isEditingName: Bool = false
    @FocusState private var isTextFieldFocused: Bool
    
    // Dynamic query that includes search filtering so no separate computed filter is needed.
    @Query(
        filter: #Predicate<Address> { !$0.isArchived && $0.folder?.id == nil },
        sort: [SortDescriptor(\Address.createdAt, order: .reverse)]
    ) var addressesWithoutFolder: [Address]
    
    var folder: Folder
    
    init(folder: Folder) {
        self.folder = folder
        _folderName = State(wrappedValue: folder.name)
    }
    
    var body: some View {
        let accentColor = appController.accentColor(colorScheme: colorScheme)
#if os(iOS)
        IOSFolderInfoBuilder(accentColor)
#elseif os(macOS)
        MacFolderInfoBuilder()
#endif
    }
    
#if os(iOS)
    @ViewBuilder
    private func IOSFolderInfoBuilder(_ accentColor: Color) -> some View {
        NavigationView {
            List {
                Section {
                    if let addresses = folder.addresses, !addresses.isEmpty {
                        ForEach(addresses) { address in
                            IOSAddressTile(address, mode: false)
                        }
                    } else {
                        Text("No Addresses in this folder")
                    }
                }
                
                Section("Available Addresses") {
                    if !addressesWithoutFolder.isEmpty {
                        ForEach(addressesWithoutFolder) { address in
                            IOSAddressTile(address, mode: true)
                        }
                    } else {
                        Text("No Addresses available")
                    }
                }
            }
            .navigationTitle(getFolderNameBinding())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", systemImage: "checkmark") {
                        dismiss()
                    }
                    .tint(accentColor)
                }
            }
        }
    }
    
    /// mode = true => Add
    /// mode = false => Remove
    @ViewBuilder
    private func IOSAddressTile(_ address: Address, mode: Bool) -> some View {
        let iconName = mode ? "plus.circle.fill" : "minus.circle.fill"
        let color: Color = mode ? .green : .red
        
        Button {
            if mode {
                addAddress(address, to: folder)
            } else {
                removeAddress(address, from: folder)
            }
        } label: {
            HStack {
                Label(address.ifNameElseAddress, systemImage: "tray")
                Spacer()
                Image(systemName: iconName)
                    .foregroundStyle(color)
            }
        }
    }
#endif

#if os(macOS)
    @ViewBuilder
    private func MacFolderInfoBuilder() -> some View {
        VStack {
            HStack {
                if isEditingName {
                    TextField("Folder Name", text: getFolderNameBinding())
                        .font(.title.bold())
                        .controlSize(.large)
                        .textFieldStyle(.plain)
                        .focused($isTextFieldFocused)
                        .onSubmit {
                            isEditingName = false
                        }
                } else {
                    Text(folder.name)
                        .font(.title.bold())
                }
                Spacer()
                Button(isEditingName ? "Done" : "Edit") {
                    withAnimation {
                        isEditingName.toggle()
                        isTextFieldFocused.toggle()
                    }
                }
            }
            .padding()
            
            MacCustomSection {
                if let addresses = folder.addresses, !addresses.isEmpty {
                    AddlessesListBuilder(addresses, mode: false)
                } else {
                    ScrollView {
                        Text("No Addresses in this folder")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.bottom)
            
            MacCustomSection {
                if !addressesWithoutFolder.isEmpty {
                    AddlessesListBuilder(addressesWithoutFolder, mode: true)
                } else {
                    ScrollView {
                        Text("No Addresses without folder available")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.bottom)
        }
    }
    
    /// mode = true => Add
    /// mode = false => Remove
    @ViewBuilder
    private func AddlessesListBuilder(_ addresses: [Address], mode: Bool) -> some View {
        ScrollView {
            ForEach(addresses) { address in
                MacAddressTile(address, mode: mode)
            }
        }
    }
    
    /// mode = true => Add
    /// mode = false => Remove
    @ViewBuilder
    private func MacAddressTile(_ address: Address, mode: Bool) -> some View {
        let iconName = mode ? "plus.circle.fill" : "minus.circle.fill"
        let helpText = "\(mode ? "Add" : "Remove") address from folder"
        let color: Color = mode ? .green : .red
        HStack {
            Label(address.ifNameElseAddress, systemImage: "tray")
            Spacer()
            Button {
                if mode {
                    addAddress(address, to: folder)
                } else {
                    removeAddress(address, from: folder)
                }
            } label: {
                Image(systemName: iconName)
                    .foregroundStyle(color)
            }
            .buttonStyle(.plain)
            .help(helpText)
        }
        .padding(.vertical, 5)
        .padding(.trailing, 15)
    }
#endif
    
    private func removeAddress(_ address: Address, from folder: Folder) {
        folder.addresses?.removeAll { $0.id == address.id}
        try? modelContext.save()
    }
    
    private func addAddress(_ address: Address, to folder: Folder) {
        if address.folder == nil { // only if the address does not already belong to an address
            folder.addresses?.append(address)
            address.folder = folder
            try? modelContext.save()
        }
    }
    
    private func getFolderNameBinding() -> Binding<String> {
        Binding {
            folderName
        } set: { newVal in
            guard !newVal.isEmpty else { return }
            folderName = newVal
            folder.name = newVal
            try? modelContext.save()
        }
    }
}
