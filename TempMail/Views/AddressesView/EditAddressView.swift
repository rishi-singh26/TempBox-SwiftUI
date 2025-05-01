//
//  EditAddressView.swift
//  TempMail
//
//  Created by Rishi Singh on 01/05/25.
//

import SwiftUI
import MailTMSwift

struct EditAddressView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var accountsController: AccountsController
    
    @State private var accountName: String = ""
    
    var account: Account
    
    init(account: Account) {
        self.account = account
        self.accountName = account.name ?? ""
    }

    var body: some View {
#if os(iOS)
        IOSEditAddress()
#elseif os(macOS)
        MacOSEditAddress()
#endif
    }
    
    @ViewBuilder
    func IOSEditAddress() -> some View {
        NavigationView {
            Form {
                Section(footer: Text("Account name appears on the accounts list screen.")) {
                    TextField("Account name", text: $accountName)
                }
            }
            .navigationTitle("Edit Address Name")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        account.name = accountName
                        accountsController.updateAccount(account)
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.headline)
                    }

                }
//#endif
            }
        }
    }
    
    @ViewBuilder
    func MacOSEditAddress() -> some View {
        VStack {
            HStack {
                Text("Edit Address Name")
                    .font(.title.bold())
                Spacer()
            }
            .padding()
            ScrollView {
                Form {
                    MacCustomSection(footer: "Address name appears on the addresses list screen.") {
                        HStack {
                            Text("Account name (Optional)")
                                .frame(width: 200, alignment: .leading)
                            Spacer()
                            TextField("", text: $accountName)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            account.name = accountName
                            accountsController.updateAccount(account)
                            dismiss()
                        } label: {
                            Text("Done")
                                .font(.headline)
                        }
                        
                    }
                    //#endif
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AccountsController.shared)
}
