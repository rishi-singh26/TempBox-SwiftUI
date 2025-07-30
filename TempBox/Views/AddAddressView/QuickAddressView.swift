//
//  QuickAddressView.swift
//  TempBox
//
//  Created by Rishi Singh on 30/07/25.
//

#if os(iOS)
import SwiftUI
import SwiftData

struct QuickAddressView: View {
    @EnvironmentObject private var addressesController: AddressesController
    
    @State private var isLoading: Bool = true
    @State private var quickAddressesFolder: Folder?
    @State private var account: Account?
    @State private var password: String?
    @State private var isPasswordBlurred: Bool = true
    
    @State private var folderError: String? = nil
    @State private var addressError: String? = nil
    
    @Environment(\.modelContext) private var modelContext
    
    var accentColor: Color
    var cancel: () -> Void
    var dismiss: () -> Void
    
    var body: some View {
        VStack {
            BuildExpandedHeader()
            List {
                if let account = account, let password = password {
                    Section(footer: MarkdownLinkText(markdownText: "If you wish to use this address on Web browser, You can copy the credentials to use on [mail.tm](https://www.mail.tm) official website. Please note, the password cannot be reset or changed.")) {
                        HStack {
                            Text(account.address)
                            Spacer()
                            Button {
                                account.address.copyToClipboard()
                            } label: {
                                Image(systemName: "doc.on.doc")
                            }
                            .help("Copy email address")
                        }
                        HStack {
                            Text(password)
                             .blur(radius: isPasswordBlurred ? 5 : 0)
                             .onTapGesture {
                                 withAnimation {
                                     isPasswordBlurred.toggle()
                                 }
                             }
                            Spacer()
                            Button {
                                password.copyToClipboard()
                            } label: {
                                Image(systemName: "doc.on.doc")
                            }
                            .help("Copy password")
                        }
                    }
                }
                
                Section {
                    if addressError == nil {
                        HStack {
                            Text(isLoading ? "Generating..." : "Address saved to Quick Addresses folder")
                                .font(.caption)
                            Spacer()
                            if isLoading {
                                ProgressView()
                                    .controlSize(.small)
                            }
                        }
                    } else {
                        HStack {
                            Text(addressError!)
                                .font(.caption)
                                .foregroundStyle(.red)
                            Spacer()
                            Button("Retry", action: retryCreate)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .accentColor(accentColor)
        .onAppear {
            Task { await getOrCreate() }
        }
    }
    
    @ViewBuilder
    private func BuildExpandedHeader() -> some View {
        HStack {
            Button(action: cancel) {
                Text("Cancel")
                    .foregroundStyle(accentColor)
            }
            Spacer(minLength: 0)
            Text("Quick Address")
                .font(.headline)
                .fontWeight(.semibold)
            Spacer(minLength: 0)
            Button(action: dismiss) {
                Text("Done")
                    .fontWeight(.bold)
                    .foregroundStyle(accentColor)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
    }
    
    private func createAddress() async {
        guard quickAddressesFolder != nil else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let (account, password) = try await MailTMService.generateRandomAccount()
            let tokenData = try await MailTMService.authenticate(address: account.address, password: password)
            
            await addressesController.addAddress(
                account: account,
                token: tokenData.token,
                password: password,
                addressName: "",
                folder: quickAddressesFolder
            )
            
            withAnimation {
                self.account = account
                self.password = password
            }
        } catch {
            withAnimation {
                addressError = error.localizedDescription
            }
        }
    }
    
    private func retryCreate() {
        Task {
            if folderError != nil {
                await getOrCreate()
            } else {
                await createAddress()
            }
        }
    }
    
    private func getOrCreate() async {
        // Try to fetch folder by fuzzy match
        if let existingFolder = fetchFolder(withIDLike: KQuickAddressesFolderIdPrefix) {
            quickAddressesFolder = existingFolder
        } else {
            let newFolderID = "\(KQuickAddressesFolderIdPrefix)\(UUID().uuidString)"
            quickAddressesFolder = createFolder(id: newFolderID, name: "Quick Addresses")
        }

        await createAddress()
    }

    
    private func fetchFolder(withIDLike id: String) -> Folder? {
        do {
            let descriptor = FetchDescriptor<Folder>(predicate: #Predicate<Folder> { $0.id.contains(id) })
            let folders = try modelContext.fetch(descriptor)
            return folders.first
        } catch {
            withAnimation {
                folderError = "Something went wrong!"
            }
            return nil
        }
    }
    
    private func createFolder(id: String, name: String) -> Folder? {
        let newFolder = Folder(id: id, name: name)

        do {
            try modelContext.save()
            return newFolder
        } catch {
            withAnimation {
                folderError = "Something went wrong!"
            }
            return nil
        }
    }
}
#endif
