//
//  MessageInfoView.swift
//  TempMail
//
//  Created by Rishi Singh on 02/05/25.
//

import SwiftUI

struct MessageInfoView: View {
    @Environment(\.dismiss) var dismiss
    
    var message: Message
    var body: some View {
#if os(iOS)
        IOSView()
#elseif os(macOS)
        MacOSView()
#endif
    }
    
#if os(iOS)
    @ViewBuilder
    func IOSView() -> some View {
        NavigationView {
            List {
                Text("Sender Name: \(message.fromName)")
                Text("Sender Email: \(message.fromAddress)")
                Button("Copy Sender Email") {
                    message.fromAddress.copyToClipboard()
                }
                Text("Received At: \(message.data.createdAt.formatRelativeString())")
            }
            .navigationTitle("Message Info")
        }
    }
#endif
    
#if os(macOS)
    @ViewBuilder
    func MacOSView() -> some View {
        VStack {
            HStack {
                Text("Message Info")
                    .font(.title.bold())
                Spacer()
                Button("Done", role: .cancel) {
                    dismiss()
                }
            }
            .padding([.horizontal, .top])
            ScrollView {
                MacCustomSection {
                    Text("Sender Name: \(message.fromName)")
                    Divider()
                    Text("Sender Email: \(message.fromAddress)")
                    Divider()
                    Button("Copy Sender Email") {
                        message.fromAddress.copyToClipboard()
                    }
                    Divider()
                    Text("Received At: \(message.data.createdAt.formatRelativeString())")
                }
                .padding(.bottom)
            }
            .navigationTitle("Message Info")
        }
    }
#endif
}

#Preview {
    ContentView()
        .environmentObject(AddressesController.shared)
        .environmentObject(AddressesViewModel.shared)
}
