//
//  MessageInfoView.swift
//  TempBox
//
//  Created by Rishi Singh on 02/05/25.
//

import SwiftUI

struct MessageInfoView: View {
    @Environment(AppStore.self) private var appStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    var message: Message
    var body: some View {
        let accentColor = appStore.accentColor(colorScheme: colorScheme)
        
        Group {
#if os(iOS)
            IOSView(accentColor)
#elseif os(macOS)
            MacOSView()
#endif
        }
    }
    
#if os(iOS)
    @ViewBuilder
    func IOSView(_ accentColor: Color) -> some View {
        NavigationView {
            List {
                Text("Sender Name: \(message.fromName ?? "")")
                Text("Sender Email: \(message.fromAddress)")
                Button("Copy Sender Email") {
                    message.fromAddress.copyToClipboard()
                }
                Text("Received At: \(message.createdAtFormatted)")
            }
            .navigationTitle("Message Info")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", systemImage: "checkmark") {
                        dismiss()
                    }
                    .tint(accentColor)
                }
            }
        }
    }
#endif
    
#if os(macOS)
    @ViewBuilder
    func MacOSView() -> some View {
        VStack(alignment: .leading) {
            Text("Message Info")
                .font(.title.bold())
                .padding([.horizontal, .top])
            
            MacCustomSection {
                Text("Sender Name: \(message.fromName ?? "")")
                Divider()
                Text("Sender Email: \(message.fromAddress)")
                Divider()
                Button("Copy Sender Email") {
                    message.fromAddress.copyToClipboard()
                }
                Divider()
                Text("Received At: \(message.createdAtFormatted)")
            }
            .padding(.bottom)
            .navigationTitle("Message Info")
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
#endif
}
