//
//  AddressInfoView.swift
//  TempBox
//
//  Created by Rishi Singh on 01/05/25.
//

import SwiftUI

struct AddressInfoView: View {
    @Environment(\.dismiss) var dismiss
    let address: Address
    
    @State private var isPasswordBlurred = true
    
    var body: some View {
#if os(iOS)
        IOSAddressInfo()
#elseif os(macOS)
        MacOSAddressInfo()
#endif
    }
    
    #if os(iOS)
    @ViewBuilder
    func IOSAddressInfo() -> some View {
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
            .navigationTitle(address.name ?? address.address.extractUsername())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    ShareLink(item: """
                              Login using the details below in TempBox application or at https://mail.tm website.
                              Email: \(address.address)
                              Password: \(address.password)
                              """)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.headline)
                    }
                }
            }
        }
    }
    #endif
    
#if os(macOS)
    @ViewBuilder
    func MacOSAddressInfo() -> some View {
        VStack {
            HStack {
                Text(address.name ?? address.address.extractUsername())
                    .font(.title.bold())
                Spacer()
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
    
    func getQuotaString(from bytes: Int, unit: SizeUnit) -> String {
        ByteConverterService(bytes: Double(bytes)).toHumanReadable(unit: unit)
    }
}

#Preview {
    ContentView()
        .environmentObject(AddressesController.shared)
}
