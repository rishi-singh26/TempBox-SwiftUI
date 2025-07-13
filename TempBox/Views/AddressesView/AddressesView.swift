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
    
    var filteredAddresses: [Address] {
        if addressesViewModel.searchText.isEmpty {
            return addressesController.addresses
        } else {
            let searchQuery = addressesViewModel.searchText.lowercased()
            return addressesController.addresses.filter { address in
                let nameMatches = address.name?.lowercased().contains(searchQuery)
                let addressMatches = address.address.lowercased().contains(searchQuery)
                return nameMatches ?? false || addressMatches
            }
        }
    }
    
    var body: some View {
        let accentColor = appController.accentColor(colorScheme: colorScheme)
        AddressesList()
#if os(iOS)
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                HStack {
                    Button(action: addressesViewModel.openNewAddressSheet) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("New Address")
                        }
                        .fontWeight(.bold)
                    }
                    .help("Create new address or login to an address")
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
                .accentColor(accentColor)
        }
        .sheet(isPresented: $addressesViewModel.isAddressInfoSheetOpen) {
            AddressInfoView(address: addressesViewModel.selectedAddForInfoSheet!)
                .accentColor(accentColor)
        }
        .sheet(isPresented: $addressesViewModel.isEditAddressSheetOpen) {
            EditAddressView(address: addressesViewModel.selectedAddForEditSheet!)
                .accentColor(accentColor)
        }
        .sheet(isPresented: $addressesViewModel.showSettingsSheet) {
            SettingsView()
                .accentColor(accentColor)
        }
        .alert("Alert!", isPresented: $addressesViewModel.showDeleteAddressAlert) {
            Button("Cancel", role: .cancel) {
            }
            Button("Delete", role: .destructive) {
                Task {
                    guard let addressForDeletion = addressesViewModel.selectedAddForDeletion else { return }
                    await addressesController.deleteAddressFromServer(address: addressForDeletion)
                    addressesViewModel.selectedAddForDeletion = nil
                }
            }
        } message: {
            Text("Are you sure you want to delete this address? This action is irreversible. Ones deleted, this address and the associated messages can not be restored.")
        }
    }
    
    @ViewBuilder
    func AddressesList() -> some View {
        let selectionBinding = Binding(get: {
            addressesController.selectedAddress
        }, set: { newVal in
            DispatchQueue.main.async {
                withAnimation {
                    addressesController.selectedAddress = newVal
                }
            }
        })
#if os(iOS)
        if DeviceType.isIphone {
            List(filteredAddresses) { address in
                AddressItemView(address: address)
            }
            .listStyle(.sidebar)
        } else {
            List(filteredAddresses, selection: selectionBinding) { address in
                NavigationLink(value: address) {
                    AddressItemView(address: address)
                }
            }
        }
#elseif os(macOS)
        List(filteredAddresses, selection: selectionBinding) { address in
            NavigationLink(value: address) {
                AddressItemView(address: address)
            }
        }
#endif
    }
}

#Preview {
    ContentView()
        .environmentObject(AddressesController.shared)
        .environmentObject(SettingsViewModel.shared)
        .environmentObject(AddressesViewModel.shared)
}
