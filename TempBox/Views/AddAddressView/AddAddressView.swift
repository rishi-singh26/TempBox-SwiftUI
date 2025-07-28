//
//  AddAddressView.swift
//  TempBox
//
//  Created by Rishi Singh on 01/05/25.
//

import SwiftUI

struct AddAddressView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject private var addressesController: AddressesController
    @EnvironmentObject private var appController: AppController
    @StateObject var controller = AddAddressViewModel()
    
    var body: some View {
        let accentColor = appController.accentColor(colorScheme: colorScheme)
        Group {
#if os(iOS)
            IOSAddAddressForm()
#else
            MacOSAddAddressForm()
#endif
        }
        .onChange(of: controller.selectedAuthMode, { _, newValue in
            if newValue == .create {
                withAnimation {
                    controller.address = ""
                    controller.shouldUseRandomPassword ? controller.generateRandomPass() : nil
                }
            } else {
                withAnimation {
                    controller.address = ""
                    controller.password = ""
                }
            }
        })
        .sheet(isPresented: $controller.showNewFolderForm) {
            NewFolderView()
                .sheetAppearanceSetup(tint: accentColor)
        }
    }
    
#if os(iOS)
    @ViewBuilder
    func IOSAddAddressForm() -> some View {
        NavigationView {
            Form {
                Section(footer: Text("Address name appears on the addresses list screen.")) {
                    TextField("Address name (Optional)", text: $controller.addressName)
                }
                
                Group {
                    switch controller.selectedAuthMode {
                    case .create:
                        IOSCreateBuilder()
                    case .login:
                        IOSLoginBuilder()
                    }
                }
                .compositingGroup()
            }
            .navigationTitle("Add Address")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if controller.isLoading {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Button {
                            Task {
                                await handleSubmit()
                            }
                        } label: {
                            Text(controller.submitBtnText)
                                .font(.headline)
                        }
                    }
                }
                ToolbarItem(placement: .principal) {
                    Picker("Select auth mode", selection: $controller.selectedAuthMode.animation(.bouncy)) {
                        ForEach(AuthTypes.allCases) { authType in
                            Text(authType.displayName).tag(authType)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 170)
                }
                
            }
            .alert(isPresented: $controller.showErrorAlert) {
                Alert(title: Text("Alert!"), message: Text(controller.errorMessage))
            }
        }
    }
    
    @ViewBuilder
    private func IOSCreateBuilder() -> some View {
        Group {
            Section {
                Picker(selection: $controller.selectedDomain) {
                    ForEach(controller.domains, id: \.self) { domain in
                        Text(domain.domain)
                    }
                } label: {
                    TextField("Address", text: $controller.address)
                        .autocapitalization(.none)
                }
                Button("Random address") {
                    controller.generateRandomAddress()
                }
                .help("Generate random address")
            }
            
            Section {
                if !controller.shouldUseRandomPassword || controller.selectedAuthMode == .login {
                    SecureField("Password", text: $controller.password)
                        .keyboardType(.asciiCapable) // This avoids suggestions bar on the keyboard.
                        .autocorrectionDisabled(true)
                }
                
                Toggle("Use random password", isOn: $controller.shouldUseRandomPassword.animation())
            }
            
            Section {
                FolderPickerView(selectedFolder: $controller.selectedFolder, showAddFolder: $controller.showNewFolderForm)
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
    }
    
    @ViewBuilder
    private func IOSLoginBuilder() -> some View {
        Section {
            TextField("Email", text: $controller.address)
                .keyboardType(.emailAddress)
            if !controller.shouldUseRandomPassword || controller.selectedAuthMode == .login {
                SecureField("Password", text: $controller.password)
                    .keyboardType(.asciiCapable) // This avoids suggestions bar on the keyboard.
                    .autocorrectionDisabled(true)
            }
        }
        
        Section {
            FolderPickerView(selectedFolder: $controller.selectedFolder, showAddFolder: $controller.showNewFolderForm)
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
                Picker("", selection: $controller.selectedAuthMode.animation()) {
                    ForEach(AuthTypes.allCases) { authType in
                        Text(authType.displayName).tag(authType)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 200)
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
                
                if controller.selectedAuthMode == .create {
                    MacOSCreateBuilder()
                } else {
                    MacOSLoginBuilder()
                }
                
                MacCustomSection {
                    FolderPickerView(selectedFolder: $controller.selectedFolder, showAddFolder: $controller.showNewFolderForm)
                }
                
                if controller.selectedAuthMode == .create {
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
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                if controller.isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Button {
                        Task {
                            await handleSubmit()
                        }
                    } label: {
                        Text(controller.submitBtnText)
                            .font(.headline)
                    }
                    .help("Submit form")
                }
            }
        }
        .alert(isPresented: $controller.showErrorAlert) {
            Alert(title: Text("Alert!"), message: Text(controller.errorMessage))
        }
    }
    
    @ViewBuilder
    private func MacOSCreateBuilder() -> some View {
        MacCustomSection {
            HStack {
                Text("Address")
                    .frame(width: 100, alignment: .leading)
                Spacer()
                TextField("", text: $controller.address)
                    .textFieldStyle(.roundedBorder)
                
                Button {
                    controller.generateRandomAddress()
                } label: {
                    Image(systemName: "arrow.2.circlepath")
                }
                .help("Generate new address")
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
            
            HStack {
                Text("Password")
                    .frame(width: 100, alignment: .leading)
                Spacer()
                TextField("", text: $controller.password)
                    .textFieldStyle(.roundedBorder)
                
                Button {
                    controller.generateRandomPass()
                } label: {
                    Image(systemName: "arrow.2.circlepath")
                }
                .help("Generate new password")
            }
        }
    }
    
    @ViewBuilder
    private func MacOSLoginBuilder() -> some View {
        MacCustomSection {
            HStack {
                Text("Email")
                    .frame(width: 100, alignment: .leading)
                Spacer()
                TextField("", text: $controller.address)
                    .textFieldStyle(.roundedBorder)
            }
            
            HStack {
                Text("Password")
                    .frame(width: 100, alignment: .leading)
                Spacer()
                TextField("", text: $controller.password)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .padding(.bottom, 20)
    }
#endif
    
    private func handleSubmit() async {
        if controller.selectedAuthMode == .create {
            await createAddress()
        } else {
            await login()
        }
    }
    
    private func createAddress() async {
        if !controller.validateInput() { return }
        
        controller.isLoading = true
        defer { controller.isLoading = false }
        
        do {
            let account = try await MailTMService.createAccount(address: controller.getEmail(), password: controller.password)
            let tokenData = try await MailTMService.authenticate(address: controller.getEmail(), password: controller.password)
            
            await addressesController.addAddress(
              account: account,
              token: tokenData.token,
              password: controller.password,
              addressName: controller.addressName,
              folder: controller.selectedFolder
            )
            dismiss()
        } catch {
            controller.errorMessage = error.localizedDescription
            controller.showErrorAlert = true
        }
    }
    
    private func login() async {
        controller.isLoading = true
        defer { controller.isLoading = false }
        
        do {
            guard isAddressUnique() else { return }
            
            let tokenData = try await MailTMService.authenticate(address: controller.getEmail(), password: controller.password)
            let account = try await MailTMService.fetchAccount(id: tokenData.id, token: tokenData.token)
            await addressesController.addAddress(
              account: account,
              token: tokenData.token,
              password: controller.password,
              addressName: controller.addressName,
              folder: controller.selectedFolder
            )
            dismiss()
        } catch {
            controller.errorMessage = error.localizedDescription
            controller.showErrorAlert = true
        }
    }
    
    private func isAddressUnique() -> Bool {
        // check if the address is a new address
        let (isUnique, isArchived) = addressesController.isAddressUnique(email: controller.getEmail())
        guard isUnique else {
            controller.errorMessage = isArchived
                ? "This address has already been added and is present in the archived addresses section in settings."
                : "This site has already been added."
            controller.showErrorAlert = true
            return false
        }
        return true
    }
}
