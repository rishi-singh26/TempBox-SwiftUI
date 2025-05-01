//
//  AddressInfoView.swift
//  TempMail
//
//  Created by Rishi Singh on 01/05/25.
//

import SwiftUI

import SwiftUI

struct AddressInfoView: View {
    @Environment(\.dismiss) var dismiss
    let account: Account
    
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
                Section(footer: Text("If you wish to use this account on Web browser, You can copy the credentials to use on [mail.tm](https://www.mail.tm) official website. Please note, the password cannot be reset or changed.")) {
                    HStack {
                        Text("Status: ")
                            .font(.headline)
                        Circle()
                            .fill(account.isDisabled ? .red : .green)
                            .frame(width: 10, height: 10)
                        Text(account.isDisabled ? "Disabled" : "Active")
                    }
                    HStack {
                        Text("Address: ")
                            .font(.headline)
                        Text(account.address)
                        Spacer()
                        Button {
                            copyToClipboard(text: account.address)
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                    }
                    HStack {
                        Text("Password: ")
                            .font(.headline)
                        Text(account.password)
                            .blur(radius: isPasswordBlurred ? 5 : 0)
                            .onTapGesture {
                                withAnimation {
                                    isPasswordBlurred.toggle()
                                }
                            }
                        Spacer()
                        Button {
                            copyToClipboard(text: account.password)
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                    }
                }
                
                Section(footer: Text("Once you reach your Quota limit, you cannot receive any more messages. Deleting your previous messages will free up your used Quota.")) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Quota usage")
                                .font(.headline)
                            Spacer()
                            Text("\(getQuotaString(from: account.used, unit: SizeUnit.KB))/\(getQuotaString(from: account.quota, unit: SizeUnit.MB))")
                                .font(.footnote)
                        }
                        .padding(.bottom, 6)
                        ProgressView(value: (Double(account.used) / 100.0), total: (Double(account.quota) / 100.0))
                    }
                }
            }
            .navigationTitle(account.name ?? account.address.extractUsername())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
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
                Text(account.name ?? account.address.extractUsername())
                    .font(.title.bold())
                Spacer()
            }
            .padding()
            ScrollView {
                MacCustomSection(footer: "If you wish to use this account on Web browser, You can copy the credentials to use on [mail.tm](https://www.mail.tm) official website. Please note, the password cannot be reset or changed.") {
                    HStack {
                        Text("Status: ")
                            .font(.headline)
                        Circle()
                            .fill(account.isDisabled ? .red : .green)
                            .frame(width: 10, height: 10)
                        Text(account.isDisabled ? "Disabled" : "Active")
                        Spacer()
                    }
                    Divider()
                    HStack {
                        Text("Address: ")
                            .font(.headline)
                        Text(account.address)
                        Spacer()
                        Button {
                            copyToClipboard(text: account.address)
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                    }
                    Divider()
                    HStack {
                        Text("Password: ")
                            .font(.headline)
                        Text(account.password)
                            .blur(radius: isPasswordBlurred ? 5 : 0)
                            .onTapGesture {
                                withAnimation {
                                    isPasswordBlurred.toggle()
                                }
                            }
                        Spacer()
                        Button {
                            copyToClipboard(text: account.password)
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                    }
                }
                
                MacCustomSection(footer: "Once you reach your Quota limit, you cannot receive any more messages. Deleting your previous messages will free up your used Quota.") {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Quota usage")
                                .font(.headline)
                            Spacer()
                            Text("\(getQuotaString(from: account.used, unit: SizeUnit.KB))/\(getQuotaString(from: account.quota, unit: SizeUnit.MB))")
                                .font(.footnote)
                        }
                        .padding(.bottom, 6)
                        Divider()
                        ProgressView(value: (Double(account.used) / 100.0), total: (Double(account.quota) / 100.0))
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
    
    func copyToClipboard(text: String) {
#if os(iOS)
        UIPasteboard.general.string = text
#elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
#else
        // Handle other platforms if needed, or provide a default
        print("Clipboard operations not supported on this platform.")
#endif
    }
    
    func getQuotaString(from bytes: Int, unit: SizeUnit) -> String {
        ByteConverterService(bytes: Double(bytes)).toHumanReadable(unit: unit)
    }
}

//struct AccountInfoView_Previews: PreviewProvider {
//    
//    static var previews: some View {
//        List {
//            Section(footer: Text("If you wish to use this account on Web browser, You can copy the credentials to use on [mail.tm](https://www.mail.tm) official website. Please note, the password cannot be reset or changed.")) {
//                HStack {
//                    Text("Status")
//                    Text("Data")
//                        .blur(radius: 5)
//                }
//            }
//            VStack {
//                ProgressView(value: 50.0, total: 100.0) {
//                    Text("20.0 MB / 40.0 MB")
//                        .font(.footnote)
//                }
//                .padding(.vertical)
//            }
//        }
//    }
//}


#Preview {
    ContentView()
        .environmentObject(AccountsController.shared)
}
