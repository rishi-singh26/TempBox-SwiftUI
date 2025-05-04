//
//  AddAddressView.swift
//  TempBox
//
//  Created by Rishi Singh on 01/05/25.
//

import SwiftUI
import MailTMSwift

struct AddAddressView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var addressesController: AddressesController
    @StateObject var controller = AddAddressViewModel()
    private let accountService = MTAccountService()

    var body: some View {
#if os(iOS)
        IOSAddAddressForm()
#else
        MacOSAddAddressForm()
#endif
    }
    
#if os(iOS)
    @ViewBuilder
    func IOSAddAddressForm() -> some View {
        NavigationView {
            Form {
                Section(footer: Text("Address name appears on the addresses list screen.")) {
                    TextField("Address name (Optional)", text: $controller.addressName)
                }
                
                if controller.isCreatingNewAddress {
                    Section {
                        Picker(selection: $controller.selectedDomain) {
                            ForEach(controller.domains, id: \.self) { domain in
                                Text(domain.domain)
                            }
                        } label: {
                            TextField("Address", text: $controller.address)
#if os(iOS)
                                .autocapitalization(.none)
#endif
                        }
                        Button("Random address") {
                            controller.generateRandomAddress()
                        }
                    }
                }
                
                if !controller.isCreatingNewAddress {
                    Section {
                        TextField("Address", text: $controller.address)
#if os(iOS)
                            .keyboardType(.emailAddress)
#endif
                    }
                }
                
                Section {
                    if !controller.shouldUseRandomPassword || !controller.isCreatingNewAddress {
                        SecureField("Password", text: $controller.password)
                            .keyboardType(.asciiCapable) // This avoids suggestions bar on the keyboard.
                            .autocorrectionDisabled(true)
                    }
                    if controller.isCreatingNewAddress {
                        Toggle("Use random password", isOn: $controller.shouldUseRandomPassword.animation())
                    }
                }
                
                HStack {
                    Image(systemName: "info.square.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)
                        .background(RoundedRectangle(cornerRadius: 5).fill(.white))
                    Text("The password once set can not be reset or changed.")
                }
                .listRowBackground(Color.yellow.opacity(0.2))
            }
            .navigationTitle("Add Address")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        createAddress()
                    } label: {
                        Text("Create")
                            .font(.headline)
                    }
                    
                }
                //                ToolbarItem(placement: .principal) {
                //                    Picker("Select auth mode", selection: $controller.selectedAuthMode) {
                //                        ForEach(controller.authOptions, id: \.self) {
                //                            Text($0)
                //                        }
                //                    }
                //                    .pickerStyle(.segmented)
                //                    .frame(width: 170)
                //                    .onChange(of: controller.selectedAuthMode) { newValue in
                //                        if newValue == "New" {
                //                            withAnimation {
                //                                controller.isCreatingNewAddress = true
                //                                controller.shouldUseRandomPassword ? controller.generateRandomPass() : nil
                //                            }
                //                        } else {
                //                            withAnimation {
                //                                controller.isCreatingNewAddress = false
                //                                controller.password = ""
                //                            }
                //                        }
                //                    }
                //                }
                
            }
            .alert(isPresented: $controller.showErrorAlert) {
                Alert(title: Text("Alert!"), message: Text(controller.errorMessage))
            }
        }
    }
#endif
    
#if os(macOS)
    @ViewBuilder
    private func MacOSAddAddressForm() -> some View {
        VStack {
            HStack {
                Text("Add Address")
                    .font(.title.bold())
                Spacer()
            }
            .padding()
            ScrollView {
                MacCustomSection(footer: "Address name appears in the sidebar.") {
                    HStack {
                        Text("Address name (Optional)")
                            .frame(width: 200, alignment: .leading)
                        Spacer()
                        TextField("", text: $controller.addressName)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                
                if controller.isCreatingNewAddress {
                    MacCustomSection {
                        if !controller.shouldUseRandomAddress || !controller.isCreatingNewAddress {
                            HStack {
                                Text("Address")
                                    .frame(width: 100, alignment: .leading)
                                Spacer()
                                TextField("", text: $controller.address)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                        if controller.isCreatingNewAddress {
                            HStack(alignment: .center) {
                                Text("Use random address")
                                    .frame(width: 200, alignment: .leading)
                                Spacer()
                                Toggle("", isOn: $controller.shouldUseRandomAddress.animation())
                                    .toggleStyle(.switch)
                            }
                        }
                        HStack(alignment: .center) {
                            Text("Domain")
                                .frame(width: 100, alignment: .leading)
                            Spacer()
                            Picker("", selection: $controller.selectedDomain) {
                                ForEach(controller.domains, id: \.self) { domain in
                                    Text(domain.domain)
                                }
                            }
                        }
                    }
                }
                
                MacCustomSection {
                    if !controller.shouldUseRandomPassword || !controller.isCreatingNewAddress {
                        HStack {
                            Text("Password")
                                .frame(width: 100, alignment: .leading)
                            Spacer()
                            TextField("", text: $controller.password)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    if controller.isCreatingNewAddress {
                        HStack(alignment: .center) {
                            Text("Use random password")
                                .frame(width: 200, alignment: .leading)
                            Spacer()
                            Toggle("", isOn: $controller.shouldUseRandomPassword.animation())
                                .toggleStyle(.switch)
                        }
                    }
                }
                
                HStack {
                    Image(systemName: "info.square.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)
                        .background(RoundedRectangle(cornerRadius: 5).fill(.white))
                    Text("The password once set can not be reset or changed.")
                }
                .padding(.vertical, 20)
                
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
                    createAddress()
                } label: {
                    Text("Create")
                        .font(.headline)
                }
                
            }
        }
        .alert(isPresented: $controller.showErrorAlert) {
            Alert(title: Text("Alert!"), message: Text(controller.errorMessage))
        }
    }
#endif
    
    func createAddress() {
        if !controller.validateInput() { return }
        let auth = MTAuth(address: controller.getEmail(), password: controller.password)
        accountService.createAccount(using: auth) { [self] (accountResult: Result<MTAccount, MTError>) in
          switch accountResult {
            case .success(let account):
              login(account: account)
            case .failure(let error):
              controller.errorMessage = error.localizedDescription
              controller.showErrorAlert = true
          }
        }
    }
    
    func login(account: MTAccount) {
        let auth = MTAuth(address: controller.getEmail(), password: controller.password)
        accountService.login(using: auth) { [self] (result: Result<String, MTError>) in
          switch result {
            case .success(let token):
              addressesController.addAddress(
                account: account,
                token: token,
                password: controller.password,
                addressName: controller.addressName
              )
              dismiss()
            case .failure(let error):
              controller.errorMessage = error.localizedDescription
              controller.showErrorAlert = true
          }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AddressesController.shared)
}
