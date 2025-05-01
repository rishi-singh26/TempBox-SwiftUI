//
//  AddressesView.swift
//  TempMail
//
//  Created by Rishi Singh on 01/05/25.
//

import SwiftUI
import SwiftData

struct AddressesView: View {
    @EnvironmentObject private var accountsController: AccountsController
    @EnvironmentObject private var addressesViewModel: AddressesViewModel
    
    var filteredAccounts: [Account] {
        if addressesViewModel.searchText.isEmpty {
            return accountsController.accounts
        } else {
            let searchQuery = addressesViewModel.searchText.lowercased()
            return accountsController.accounts.filter { account in
                let nameMatches = account.name?.lowercased().contains(searchQuery)
                let addressMatches = account.address.lowercased().contains(searchQuery)
                return nameMatches ?? false || addressMatches
            }
        }
    }

    var body: some View {
        List(selection: $accountsController.selectedAccount) {
            //                Section(header: Text("Active")) {
            ForEach(filteredAccounts) { account in
                NavigationLink {
                    MessagesView(account: account)
                } label: {
                    AddressItemView(account: account)
                }
            }
            //                }
            //            header: {
            //                    Text("Active")
            //                        .font(.title3)
            //                        .fontWeight(.bold)
            //                        .foregroundColor(.primary)
            //                        .textCase(nil)
            //                }
        }
#if os(macOS)
        .listStyle(.sidebar)
#endif
        .navigationTitle("TempBox")
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
                    Spacer()
                    Text("Powered by [mail.tm](https://www.mail.tm)")
                        .font(.footnote)
                }
            }
        }
#endif
        .searchable(text: $addressesViewModel.searchText, placement: .sidebar)
        .listStyle(.sidebar)
        .sheet(isPresented: $addressesViewModel.isNewAddressSheetOpen) {
            AddAddressView()
        }
        .sheet(isPresented: $addressesViewModel.isAccountInfoSheetOpen) {
            AddressInfoView(account: addressesViewModel.selectedAccForInfoSheet!)
        }
        .sheet(isPresented: $addressesViewModel.isEditAccountSheetOpen) {
            EditAddressView(account: addressesViewModel.selectedAccForEditSheet!)
        }
        .refreshable {
            accountsController.fetchAccounts()
        }
        .alert("Alert!", isPresented: $addressesViewModel.showDeleteAccountAlert) {
            Button("Cancel", role: .cancel) {
                
            }
            Button("Delete", role: .destructive) {
                guard let accountForDeletion = addressesViewModel.selectedAccForDeletion else { return }
                accountsController.deleteAccount(accountForDeletion)
                addressesViewModel.selectedAccForDeletion = nil
            }
        } message: {
            Text("Are you sure you want to delete this account?")
        }
        
        //            .toolbar {
        //                ToolbarItem(placement: .topBarTrailing) {
        //                    Button {
        //                        dataController.fetchAccounts()
        //                    } label: {
        //                        Label("Refresh", systemImage: "arrow.clockwise.circle")
        //                    }
        //                }
        //            }
    }
}

#Preview {
    ContentView()
        .environmentObject(AccountsController.shared)
        .environmentObject(AddressesViewModel.shared)
}
