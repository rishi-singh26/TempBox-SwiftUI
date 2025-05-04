//
//  ImportAddressesView.swift
//  TempMail
//
//  Created by Rishi Singh on 02/05/25.
//

import SwiftUI

struct ImportAddressesView: View {
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    @EnvironmentObject private var addressesController: AddressesController
    
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
        List(
            settingsViewModel.getV1Addresses(addresses: addressesController.addresses),
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
        .environment(\.editMode, .constant(.active))
        .toolbar {
            Button("Choose File") {
                settingsViewModel.pickFileForImport()
            }
        }
        .toolbar(content: {
            ToolbarItemGroup(placement: .bottomBar) {
                Button("Unselect All") {
                    settingsViewModel.selectedV1Addresses = []
                }
                Button("Select All") {
                    settingsViewModel.selectedV1Addresses = Set(settingsViewModel.getV1Addresses(addresses: addressesController.addresses))
                }
                Spacer()
                Button("Import") {
                    Task {
                        importAddresses { errorDictionary in
                            settingsViewModel.errorDict = errorDictionary
                        }
                    }
                }
                .disabled(settingsViewModel.selectedV1Addresses.isEmpty)
            }
        })
        .navigationTitle("Import Addresses")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $settingsViewModel.isPickingFile,
            allowedContentTypes: [.plainText],
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
            if settingsViewModel.v1ImportData != nil {
                MacCustomSection {
                    VStack {
                        AddressView()
                        SelectionButtons()
                    }
                }
                .padding(.bottom)
            }
        }
        .fileImporter(
            isPresented: $settingsViewModel.isPickingFile,
            allowedContentTypes: [.plainText],
            allowsMultipleSelection: false
        ) { result in
            settingsViewModel.importData(from: result)
        }
    }
    
    @ViewBuilder
    func AddressView() -> some View {
        List(
            settingsViewModel.getV1Addresses(addresses: addressesController.addresses),
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
    }
    
    @ViewBuilder
    func SelectionButtons() -> some View {
        HStack {
            Spacer()
            Button("Unselect All", role: .cancel) {
                settingsViewModel.selectedV1Addresses = []
            }
            Button("Select All") {
                settingsViewModel.selectedV1Addresses = Set(settingsViewModel.getV1Addresses(addresses: addressesController.addresses))
            }
            Button("Import") {
                Task {
                    importAddresses { errorDictionary in
                        settingsViewModel.errorDict = errorDictionary
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(settingsViewModel.selectedV1Addresses.isEmpty)
        }
    }
#endif
    
    func importAddresses(completion: @escaping ([String: String]) -> Void) {
        let addresses = settingsViewModel.selectedV1Addresses
        if addresses.isEmpty {
            completion([:])
            return
        }

        var errorMap: [String: String] = [:]
        let group = DispatchGroup()

        for address in addresses {
            group.enter()
            addressesController.loginAndSaveAddress(address: address) { status, message in
                if !status {
                    errorMap[address.id] = message
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion(errorMap)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AddressesController.shared)
        .environmentObject(AddressesViewModel.shared)
        .environmentObject(SettingsViewModel.shared)
}
