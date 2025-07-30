//
//  ArchiveView.swift
//  TempBox
//
//  Created by Rishi Singh on 12/06/25.
//

import SwiftUI
import SwiftData

struct ArchiveView: View {
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    @EnvironmentObject private var addressesController: AddressesController
    
    @Query(filter: #Predicate<Address> { $0.isArchived }, sort: [SortDescriptor(\Address.createdAt, order: .reverse)])
    private var archivedAddresses: [Address]
    
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
        Group {
            if !archivedAddresses.isEmpty {
                List(archivedAddresses, id: \.self, selection: $settingsViewModel.selectedArchivedAddresses) { address in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(address.ifNameElseAddress)
                            Text(address.ifNameThenAddress)
                                .font(.caption.bold())
                            if let safeErrMess = settingsViewModel.errorDict[address.id] {
                                Text(safeErrMess)
                                    .font(.caption.bold())
                                    .foregroundStyle(.red)
                            }
                        }
                        Spacer()
                    }
                }
            } else {
                List {
                    Text("No archived addresses")
                }
            }
        }
        .environment(\.editMode, .constant(.active))
        .toolbar(content: {
            ToolbarItemGroup(placement: .bottomBar) {
                Button("Unselect All") {
                    settingsViewModel.selectedArchivedAddresses = []
                }
                Button("Select All") {
                    settingsViewModel.selectedArchivedAddresses = Set(archivedAddresses)
                }
                Spacer()
                Button("Restore") {
                    Task {
                        await restoreAddresses()
                    }
                }
                .disabled(settingsViewModel.selectedArchivedAddresses.isEmpty)
                Button("Delete", role: .destructive) {
                    settingsViewModel.showArchAddrDeleteConf = true
                }
                .disabled(settingsViewModel.selectedArchivedAddresses.isEmpty)
            }
        })
        .navigationTitle("Archived Addresses")
        .navigationBarTitleDisplayMode(.inline)
    }
#endif
    
#if os(macOS)
    @ViewBuilder
    func MacOSView() -> some View {
        VStack(alignment: .leading) {
            MacCustomSection {
                VStack {
                    AddressView()
                    SelectionButtons()
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Archived Addresses")
    }
    
    @ViewBuilder
    func AddressView() -> some View {
        List {
            ForEach(archivedAddresses) { address in
                HStack {
                    Toggle("", isOn: Binding(get: {
                        settingsViewModel.selectedArchivedAddresses.contains(address)
                    }, set: { newVal in
                        if newVal {
                            settingsViewModel.selectedArchivedAddresses.insert(address)
                        } else {
                            settingsViewModel.selectedArchivedAddresses.remove(address)
                        }
                    }))
                    .toggleStyle(.checkbox)
                    VStack(alignment: .leading) {
                        Text(address.ifNameElseAddress)
                            .font(.body)
                        Text(address.ifNameThenAddress)
                            .font(.caption)
                    }
                    Spacer()
                    if let safeErrMess = settingsViewModel.errorDict[address.id] {
                        Text(safeErrMess)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func SelectionButtons() -> some View {
        HStack {
            Spacer()
            Button("Unselect All", role: .cancel) {
                settingsViewModel.selectedArchivedAddresses = []
            }
            Button("Select All") {
                settingsViewModel.selectedArchivedAddresses = Set(archivedAddresses)
            }
            Button("Restore") {
                Task {
                    await restoreAddresses()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(settingsViewModel.selectedArchivedAddresses.isEmpty)
            Button("Delete", role: .destructive) {
                settingsViewModel.showArchAddrDeleteConf = true
            }
            .buttonStyle(.borderedProminent)
            .disabled(settingsViewModel.selectedArchivedAddresses.isEmpty)
        }
    }
#endif
    
    func restoreAddresses() async {
        var errorMap: [String: String] = [:]
        if settingsViewModel.selectedArchivedAddresses.isEmpty {
            settingsViewModel.showAlert(with: "Select addresses to restore.")
            settingsViewModel.errorDict = errorMap
            return
        }
        
        await withTaskGroup(of: (String, String?)?.self) { group in
            for address in settingsViewModel.selectedArchivedAddresses {
                group.addTask {
                    let (status, message) = await addressesController.loginAndRestoreAddress(address: address)
                    return status ? nil : (address.id, message)
                }
            }
            
            for await result in group {
                if let (id, message) = result {
                    errorMap[id] = message
                }
            }
        }
        
        settingsViewModel.selectedArchivedAddresses.removeAll()
        settingsViewModel.errorDict = errorMap
    }
}
