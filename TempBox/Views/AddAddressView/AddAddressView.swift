//
//  AddAddressView.swift
//  TempBox
//
//  Created by Rishi Singh on 01/05/25.
//

import SwiftUI
#if os(iOS)
import SwiftData
#endif

struct AddAddressView: View {
#if os(iOS)
    var cancel: () -> Void
    var dismiss: () -> Void
    
    @FocusState private var addressNameFocus: Bool
    @FocusState private var addressFocus: Bool
    @FocusState private var passwordFocus: Bool
#elseif os(macOS)
    @Environment(\.dismiss) var dismiss
#endif
    
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject private var addressesController: AddressesController
    @EnvironmentObject private var appController: AppController
    @StateObject var controller = AddAddressViewModel()
    
#if os(iOS)
    @Query(sort: [SortDescriptor(\Folder.name, order: .forward)])
    private var folders: [Folder]
#endif
    
    var body: some View {
        let accentColor = appController.accentColor(colorScheme: colorScheme)
        Group {
#if os(iOS)
            IOSAddAddressForm()
#else
            MacOSAddAddressForm()
#endif
        }
        .onAppear(perform: {
            Task {
                try? await Task.sleep(for: .seconds(0.4))
                await controller.loadDomains()
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
        let accentColor = appController.accentColor(colorScheme: colorScheme)
        VStack(spacing: 0) {
//            Text("Add Address")
//                .font(.headline)
//                .fontWeight(.semibold)
            BuildHeader(accentColor: accentColor)
            List {
                AddressNameInputBuilder()
                
                if controller.showErrorAlert {
                    BuildErrorSection()
                }
                
                switch controller.selectedAuthMode {
                case .create:
                    IOSCreateBuilder(accentColor: accentColor)
                case .login:
                    IOSLoginBuilder(accentColor: accentColor)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
    }
    
    @ViewBuilder
    private func IOSCreateBuilder(accentColor: Color) -> some View {
        Section {
            TextField("Address", text: $controller.address)
                .autocapitalization(.none)
                .focused($addressFocus)
            
            Button("Random address", action: controller.generateRandomAddress)
            .foregroundStyle(accentColor)
            .help("Generate random address")
            
            Picker("Select Domain", selection: $controller.selectedDomain) {
                ForEach(controller.domains, id: \.self) { domain in
                    Text(domain.domain)
                }
            }
        }.customListStyle()
        
        Section {
            if !controller.shouldUseRandomPassword || controller.selectedAuthMode == .login {
                SecureField("Password", text: $controller.password)
                    .keyboardType(.asciiCapable) // This avoids suggestions bar on the keyboard.
                    .autocorrectionDisabled(true)
                    .focused($passwordFocus)
            }
            
            Toggle("Use random password", isOn: $controller.shouldUseRandomPassword.animation())
        }.customListStyle()
        
        FolderPickerBuilder(accentColor: accentColor)
        
        Section {
            HStack {
                Image(systemName: "info.square.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                    .background(RoundedRectangle(cornerRadius: 5).fill(.white))
                Text("The password once set can not be reset or changed.")
            }
        }.yellowListStyle()
    }
    
    @ViewBuilder
    private func IOSLoginBuilder(accentColor: Color) -> some View {
        Section {
            TextField("Email", text: $controller.address)
                .keyboardType(.emailAddress)
                .focused($addressFocus)
            if !controller.shouldUseRandomPassword || controller.selectedAuthMode == .login {
                SecureField("Password", text: $controller.password)
                    .keyboardType(.asciiCapable) // This avoids suggestions bar on the keyboard.
                    .autocorrectionDisabled(true)
                    .focused($passwordFocus)
            }
        }.customListStyle()
        
        FolderPickerBuilder(accentColor: accentColor)
    }
    
    @ViewBuilder
    private func BuildHeader(accentColor: Color) -> some View {
        HStack(alignment: .center) {
            Button("Cancel", action: handleCancel)
                .foregroundStyle(accentColor)
                .frame(width: 60)
            Spacer(minLength: 0)
            AuthModeBuilder()
            Spacer(minLength: 0)
            Group {
                if controller.isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Button {
                        Task {
                            await handleSubmitIOS()
                        }
                    } label: {
                        Text(controller.submitBtnText)
                            .fontWeight(.bold)
                            .foregroundStyle(accentColor)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(width: 60)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 25)
    }
    
    @ViewBuilder
    private func AuthModeBuilder() -> some View {
        Picker("Select auth mode", selection: $controller.selectedAuthMode.animation(.bouncy)) {
            ForEach(AuthTypes.allCases) { authType in
                Text(authType.displayName).tag(authType)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 150)
    }
    
    @ViewBuilder
    private func AddressNameInputBuilder() -> some View {
        Section {
            TextField("Address name (Optional)", text: $controller.addressName)
                .focused($addressNameFocus)
        } footer: {
            Text("Address name appears on the addresses list screen.")
                .font(.caption)
        }.customListStyle()
    }
    
    @ViewBuilder
    private func BuildErrorSection() -> some View {
        Section {
            HStack {
                Text(controller.errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                Spacer()
                
                Button(action: controller.hideError) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                .buttonStyle(.plain)
            }
        }.customListStyle()
    }
    
    @ViewBuilder
    private func FolderPickerBuilder(accentColor: Color) -> some View {
        Section {
            Picker("Select Folder", selection: $controller.selectedFolder) {
                Text("No Folder")
                    .tag(nil as Folder?)
                ForEach(folders) { folder in
                    Text(folder.name)
                        .tag(folder)
                }
            }
            .pickerStyle(.menu)
            .tint(accentColor)
        }.customListStyle()
    }
    
    private func resetFocusState() {
        addressNameFocus = false
        addressFocus = false
        passwordFocus = false
    }
    
    private func handleCancel() {
        resetFocusState()
        cancel()
    }
    
    private func handleSubmitIOS() async {
        resetFocusState()
        await handleSubmit()
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
                .padding(.bottom, controller.selectedAuthMode == .create ? 0 : 20)
                
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
            controller.showError(with: error.localizedDescription)
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
            controller.showError(with: error.localizedDescription)
        }
    }
    
    private func isAddressUnique() -> Bool {
        // check if the address is a new address
        let (isUnique, isArchived) = addressesController.isAddressUnique(email: controller.getEmail())
        guard isUnique else {
            controller.showError(with: isArchived
                                 ? "This address has already been added and is present in the archived addresses section in settings."
                                 : "This site has already been added.")
            return false
        }
        return true
    }
}

#if os(iOS)
fileprivate extension View {
    @ViewBuilder
    func customListStyle() -> some View {
        self
            .listRowSpacing(15)
            .listSectionSpacing(15)
    }
    
    @ViewBuilder
    func yellowListStyle() -> some View {
        self
            .listRowBackground(Color.yellow.opacity(0.2))
            .listRowSpacing(15)
            .listSectionSpacing(15)
    }
}
#endif
