//
//  AddressInfoView.swift
//  TempBox
//
//  Created by Rishi Singh on 01/05/25.
//

import SwiftUI

struct AddressInfoView: View {
    @EnvironmentObject private var appController: AppController
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var isPasswordBlurred = true
    @State private var addressName = ""
    @State private var showAddFolderSheet: Bool = false
    @State private var isEditingName: Bool = false
    @FocusState private var isTextFieldFocused: Bool
    
    let address: Address
    
    init(address: Address) {
        self.address = address
        _addressName = State(wrappedValue: address.ifNameElseAddress.extractUsername())
    }
    
    var body: some View {
        let accentColor = appController.accentColor(colorScheme: colorScheme)
        Group {
#if os(iOS)
            IOSAddressInfo()
#elseif os(macOS)
            MacOSAddressInfo()
#endif
        }
        .sheet(isPresented: $showAddFolderSheet) {
            NewFolderView()
                .sheetAppearanceSetup(tint: accentColor)
        }
    }
    
    #if os(iOS)
    @ViewBuilder
    func IOSAddressInfo() -> some View {
        let (addressNameBinding, folderBinding) = getNameAndFolderBindings()
        
        NavigationView {
            List {
                Section(footer: MarkdownLinkText(markdownText: "If you wish to use this address on Web browser, You can copy the credentials to use on [mail.tm](https://www.mail.tm) official website. Please note, the password cannot be reset or changed.")) {
                    HStack {
                        Text("Status: ")
                            .font(.headline)
                        Circle()
                            .fill(address.isArchived ? .red : .green)
                            .frame(width: 10, height: 10)
                        Text(address.isArchived ? "Archived" : "Active")
                    }
                    HStack {
                        Text("Address: ")
                            .font(.headline)
                        Text(address.address)
                        Spacer()
                        Button {
                            address.address.copyToClipboard()
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                        .help("Copy email address")
                    }
                    HStack {
                        Text("Password: ")
                            .font(.headline)
                        Text(address.password)
                            .blur(radius: isPasswordBlurred ? 5 : 0)
                            .onTapGesture {
                                withAnimation {
                                    isPasswordBlurred.toggle()
                                }
                            }
                        Spacer()
                        Button {
                            address.password.copyToClipboard()
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                        .help("Copy password")
                    }
                }
                
                Section {
                    FolderPickerView(selectedFolder: folderBinding, showAddFolder: $showAddFolderSheet)
                }
                
                Section(footer: Text("Once you reach your Quota limit, you cannot receive any more messages. Deleting your previous messages will free up your used Quota.")) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Quota usage")
                                .font(.headline)
                            Spacer()
                            Text("\(getQuotaString(from: address.used, unit: SizeUnit.KB))/\(getQuotaString(from: address.quota, unit: SizeUnit.MB))")
                                .font(.footnote)
                        }
                        .padding(.bottom, 6)
                        ProgressView(value: (Double(address.used) / 100.0), total: (Double(address.quota) / 100.0))
                    }
                }
            }
            .navigationTitle(addressNameBinding)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    ShareLink(item: """
                              Login using the details below in TempBox application or at https://mail.tm website.
                              Email: \(address.address)
                              Password: \(address.password)
                              """)
                }
            }
        }
    }
    #endif
    
#if os(macOS)
    @ViewBuilder
    func MacOSAddressInfo() -> some View {
        let (addressNameBinding, folderBinding) = getNameAndFolderBindings()
        
        VStack {
            HStack {
                if isEditingName {
                    TextField("Address Name", text: addressNameBinding)
                        .font(.title.bold())
                        .controlSize(.large)
                        .textFieldStyle(.plain)
                        .focused($isTextFieldFocused)
                        .onSubmit {
                            isEditingName = false
                        }
                } else {
                    Text(address.ifNameElseAddress.extractUsername())
                        .font(.title.bold())
                }
                Spacer()
                Button(isEditingName ? "Done" : "Edit") {
                    withAnimation {
                        isEditingName.toggle()
                        isTextFieldFocused.toggle()
                    }
                }
            }
            .padding()
            ScrollView {
                MacCustomSection(footer: "If you wish to use this address on Web browser, You can copy the credentials to use on [mail.tm](https://www.mail.tm) official website. Please note, the password cannot be reset or changed.") {
                    HStack {
                        Text("Status: ")
                            .font(.headline)
                        Circle()
                            .fill(address.isArchived ? .red : .green)
                            .frame(width: 10, height: 10)
                        Text(address.isArchived ? "Disabled" : "Active")
                        Spacer()
                    }
                    Divider()
                    HStack {
                        Text("Address: ")
                            .font(.headline)
                        Text(address.address)
                        Spacer()
                        Button {
                            address.address.copyToClipboard()
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                        .help("Copy email address")
                    }
                    Divider()
                    HStack {
                        Text("Password: ")
                            .font(.headline)
                        Text(address.password)
                            .blur(radius: isPasswordBlurred ? 5 : 0)
                            .onTapGesture {
                                withAnimation {
                                    isPasswordBlurred.toggle()
                                }
                            }
                        Spacer()
                        Button {
                            address.password.copyToClipboard()
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                        .help("Copy password")
                    }
                }
                
                MacCustomSection {
                    FolderPickerView(selectedFolder: folderBinding, showAddFolder: $showAddFolderSheet)
                }
                
                MacCustomSection(footer: "Once you reach your Quota limit, you cannot receive any more messages. Deleting your previous messages will free up your used Quota.") {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Quota usage")
                                .font(.headline)
                            Spacer()
                            Text("\(getQuotaString(from: address.used, unit: SizeUnit.KB))/\(getQuotaString(from: address.quota, unit: SizeUnit.MB))")
                                .font(.footnote)
                        }
                        .padding(.bottom, 6)
                        Divider()
                        ProgressView(value: (Double(address.used) / 100.0), total: (Double(address.quota) / 100.0))
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.headline)
                }
            }
        }
    }
#endif
    
    private func getQuotaString(from bytes: Int, unit: SizeUnit) -> String {
        ByteConverterService(bytes: Double(bytes)).toHumanReadable(unit: unit)
    }
    
    private func getNameAndFolderBindings() -> (Binding<String>, Binding<Folder?>) {
        let addressNameBinding = Binding<String> {
            addressName
        } set: { newName in
            guard !newName.isEmpty else { return }
            addressName = newName
            address.name = newName
        }
        
        let folderBinding = Binding<Folder?> {
            address.folder
        } set: { newVal in
            if let safeVal = newVal {
                address.folder = safeVal
                var addresses: [Address] = safeVal.addresses ?? []
                addresses.append(address)
                safeVal.addresses = Array(Set(addresses))
            } else {
                let prevFolder = address.folder
                address.folder = newVal
                var addresses: [Address] = prevFolder?.addresses ?? []
                addresses.removeAll { $0.id == address.id }
                prevFolder?.addresses = addresses
            }
        }
        
        return (addressNameBinding, folderBinding)
    }
}
