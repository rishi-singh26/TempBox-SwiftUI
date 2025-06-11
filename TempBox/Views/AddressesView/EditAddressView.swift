//
//  EditAddressView.swift
//  TempBox
//
//  Created by Rishi Singh on 01/05/25.
//

import SwiftUI

struct EditAddressView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var addressesController: AddressesController
    
    @State private var addressName: String = ""
    
    var address: Address
    
    init(address: Address) {
        self.address = address
        self.addressName = address.name ?? ""
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
                Section(footer: Text("Address name appears on the addresses list screen.")) {
                    TextField("Address name", text: $addressName)
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
                        address.name = addressName
                        addressesController.updateAdress(address)
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
                            Text("Address name (Optional)")
                                .frame(width: 200, alignment: .leading)
                            Spacer()
                            TextField("", text: $addressName)
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
                            address.name = addressName
                            addressesController.updateAdress(address)
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
        .environmentObject(AddressesController.shared)
}
