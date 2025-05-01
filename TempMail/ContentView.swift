//
//  ContentView.swift
//  TempMail
//
//  Created by Rishi Singh on 01/05/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject private var accountsController: AccountsController
    @EnvironmentObject private var addressesViewModel: AddressesViewModel
    
    var body: some View {
#if os(iOS)
        NavigationView {
            AddressesView()
        }
#elseif os(macOS)
        NavigationSplitView {
            NewAddressBtn()
            AddressesView()
            Text("Powered by [mail.tm](https://www.mail.tm)")
                .font(.footnote)
        } content: {
            MessagesView(account: accountsController.selectedAccount)
        } detail: {
            MessageDetailView(message: accountsController.selectedMessage, account: accountsController.selectedAccount)
        }

#endif
    }
}

struct NewAddressBtn: View {
    @EnvironmentObject private var addressesViewModel: AddressesViewModel
    
    var body: some View {
        Button(action: addressesViewModel.openNewAddressSheet, label: {
            VStack(alignment: .leading) {
                HStack {
                    Text("New Address")
                        .foregroundStyle(.primary)
                        .padding(.leading, 4)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.primary)
                }
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(6)
            }
        })
        .padding(.horizontal)
        .padding(.vertical, 5)
        .buttonStyle(.plain)
        .keyboardShortcut(.init("a", modifiers: [.command]))
    }
}

#Preview {
    ContentView()
        .environmentObject(AccountsController.shared)
}
