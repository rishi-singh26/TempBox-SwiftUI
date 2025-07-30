//
//  ImportAddressesView.swift
//  TempBox
//
//  Created by Rishi Singh on 02/05/25.
//

import SwiftUI
import SwiftData

struct ImportAddressesView: View {
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    @EnvironmentObject private var addressesController: AddressesController
    
    @Query(filter: #Predicate<Address> { !$0.isArchived }, sort: [SortDescriptor(\Address.createdAt, order: .reverse)])
    private var addresses: [Address]
    
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
            if settingsViewModel.importDataVersion == ExportVersionOne.staticVersion {
                List(
                    settingsViewModel.getV1Addresses(addresses: addresses),
                    id: \.self,
                    selection: $settingsViewModel.selectedV1Addresses
                ) { address in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(address.addressName.isEmpty ? address.authenticatedUser.account.address : address.addressName)
                            Text(address.addressName.isEmpty ? "" : address.authenticatedUser.account.address)
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
            } else if settingsViewModel.importDataVersion == ExportVersionTwo.staticVersion {
                List(
                    settingsViewModel.getV2Addresses(addresses: addresses),
                    id: \.self,
                    selection: $settingsViewModel.selectedV2Addresses
                ) { address in
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
                Button(action: {
                    settingsViewModel.pickFileForImport()
                }) {
                    Text("Choose File")
                        .font(.title3)
                        .foregroundColor(.blue)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 15)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(10)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .environment(\.editMode, .constant(.active))
        .toolbar {
            Button("Choose File") {
                settingsViewModel.pickFileForImport()
            }
        }
        .toolbar(content: {
            ToolbarItemGroup(placement: .bottomBar) {
                Button("Unselect All") {
                    settingsViewModel.unSelectAllAddresses()
                }
                Button("Select All") {
                    settingsViewModel.selectAllAddresses(addresses: addresses)
                }
                Spacer()
                Button("Import") {
                    Task {
                        await importAddresses { errorDictionary in
                            settingsViewModel.errorDict = errorDictionary
                        }
                    }
                }
                .disabled(settingsViewModel.isImportButtonDisabled)
            }
        })
        .navigationTitle("Import Addresses")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $settingsViewModel.isPickingFile,
            allowedContentTypes: [.plainText, .json],
            allowsMultipleSelection: false
        ) { result in
            settingsViewModel.importData(from: result)
        }
    }
#endif
    
#if os(macOS)
    @ViewBuilder
    func MacOSView() -> some View {
        VStack(alignment: .leading) {
            MacCustomSection {
                HStack {
                    Text("Import from file")
                    Spacer()
                    Button("Choose File") {
                        settingsViewModel.pickFileForImport()
                    }
                }
            }
            .padding(.top)
            if settingsViewModel.v1ImportData == nil && settingsViewModel.v2ImportData == nil {
                Spacer()
            }
            if settingsViewModel.v1ImportData != nil || settingsViewModel.v2ImportData != nil {
                MacCustomSection {
                    VStack {
                        AddressView()
                        SelectionButtons()
                    }
                }
                .padding(.bottom)
            }
        }
        .navigationTitle("Import Addresses")
        .fileImporter(
            isPresented: $settingsViewModel.isPickingFile,
            allowedContentTypes: [.plainText, .json],
            allowsMultipleSelection: false
        ) { result in
            settingsViewModel.importData(from: result)
        }
    }
    
    @ViewBuilder
    func AddressView() -> some View {
        Group {
            if settingsViewModel.importDataVersion == ExportVersionOne.staticVersion {
                List(
                    settingsViewModel.getV1Addresses(addresses: addresses),
                    selection: $settingsViewModel.selectedV1Addresses
                ) { address in
                    HStack {
                        Toggle("", isOn: Binding(get: {
                            settingsViewModel.selectedV1Addresses.contains(address)
                        }, set: { newVal in
                            if newVal {
                                settingsViewModel.selectedV1Addresses.insert(address)
                            } else {
                                settingsViewModel.selectedV1Addresses.remove(address)
                            }
                        }))
                        .toggleStyle(.checkbox)
                        VStack(alignment: .leading) {
                            Text(address.addressName.isEmpty ? address.authenticatedUser.account.address : address.addressName)
                                .font(.body)
                            Text(address.addressName.isEmpty ? "" : address.authenticatedUser.account.address)
                                .font(.caption)
                        }
                        Spacer()
                        if let safeErrMess = settingsViewModel.errorDict[address.id] {
                            Text(safeErrMess)
                        }
                    }
                }
            } else if settingsViewModel.importDataVersion == ExportVersionTwo.staticVersion {
                List(
                    settingsViewModel.getV2Addresses(addresses: addresses),
                    selection: $settingsViewModel.selectedV2Addresses
                ) { address in
                    HStack {
                        Toggle("", isOn: Binding(get: {
                            settingsViewModel.selectedV2Addresses.contains(address)
                        }, set: { newVal in
                            if newVal {
                                settingsViewModel.selectedV2Addresses.insert(address)
                            } else {
                                settingsViewModel.selectedV2Addresses.remove(address)
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
    }
    
    @ViewBuilder
    func SelectionButtons() -> some View {
        HStack {
            Spacer()
            Button("Unselect All", role: .cancel) {
                settingsViewModel.unSelectAllAddresses()
            }
            Button("Select All") {
                settingsViewModel.selectAllAddresses(addresses: addresses)
            }
            Button("Import") {
                Task {
                    await importAddresses { errorDictionary in
                        settingsViewModel.errorDict = errorDictionary
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(settingsViewModel.isImportButtonDisabled)
        }
    }
#endif
    
    func importAddresses(completion: @escaping ([String: String]) -> Void) async {
        var errorMap: [String: String] = [:]
        
        if settingsViewModel.importDataVersion == ExportVersionOne.staticVersion {
            let addresses = settingsViewModel.selectedV1Addresses
            if addresses.isEmpty {
                completion([:])
                return
            }
            
            await withTaskGroup(of: (String, String?)?.self) { group in
                for address in addresses {
                    group.addTask {
                        let (status, message) = await addressesController.loginAndSaveAddress(address: address)
                        return status ? nil : (address.id, message)
                    }
                }
                
                for await result in group {
                    if let (id, message) = result {
                        errorMap[id] = message
                    }
                }
            }
            
            settingsViewModel.selectedV1Addresses.removeAll()
            
            completion(errorMap)
        } else if settingsViewModel.importDataVersion == ExportVersionTwo.staticVersion {
            let addresses = settingsViewModel.selectedV2Addresses
            if addresses.isEmpty {
                completion([:])
                return
            }
            
            await withTaskGroup(of: (String, String?)?.self) { group in
                for address in addresses {
                    group.addTask {
                        let (status, message) = await addressesController.loginAndSaveAddress(address: address)
                        return status ? nil : (address.id, message)
                    }
                }
                
                for await result in group {
                    if let (id, message) = result {
                        errorMap[id] = message
                    }
                }
            }
            
            settingsViewModel.selectedV2Addresses.removeAll()
            
            completion(errorMap)
        }
    }
}
