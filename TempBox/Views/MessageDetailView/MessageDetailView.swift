//
//  MessageDetailView.swift
//  TempBox
//
//  Created by Rishi Singh on 01/05/25.
//

import SwiftUI

struct MessageDetailView: View {
    @EnvironmentObject private var addressesController: AddressesController
    
    @State var showMessageInfoSheet = false
    
    let message: Message
    let address: Address
    
//    private func getHeaderHTML(_ message: Message) -> String {
//        "<div style='display: flex; \(DeviceType.isIphone ? "margin-left: 10px;" : "") margin-bottom: 10px;'><div style='display: flex; width: 40px; height: 40px; border-radius: 20px; background-color: #007AFF; align-items: center; justify-content: center; color: white; font-weight: bold;'>\(message.fromName.getInitials())</div><div style='margin-left: 10px;'><div style='font-weight: bold;'>\(message.fromName)</div><a href='mailto:\(message.fromAddress)'>\(message.fromAddress)</a></div></div><div style='display: flex; flex-direction: row; justify-content: flex-end; align-items: center; color: #8f8f8f; font-size: 16px; padding: 5px 15px;'>\(message.data.createdAt.formatRelativeString())</div>";
//    }
        
    var body: some View {
        VStack(alignment: .leading) {
            MessageHeaderView(message: message)
            Text(message.subject)
                .font(.title3.bold())
            if let selectedMessage = addressesController.selectedCompleteMessage,
               selectedMessage.id == message.id,
               let html = selectedMessage.html?.first {
                    WebView(html: html)
            }
            else {
                Spacer()
            }
            if addressesController.loadingCompleteMessage {
                EmptyView()
            }
        }
        .onAppear(perform: {
            Task {
                await addressesController.fetchCompleteMessage(of: message, address: address)
                await addressesController.updateMessageSeenStatus(messageData: message, address: address, seen: true)
            }
        })
        .sheet(isPresented: $showMessageInfoSheet, content: {
            MessageInfoView(message: message)
        })
        .toolbar(content: {
            ToolbarItem {
                Button("Message Information", systemImage: "info.circle") {
                    showMessageInfoSheet = true
                }
            }
        })
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
}

struct EmptyView: View {
    var body: some View {
        VStack {
            Spacer()
            ProgressView()
                .frame(width: 25, height: 25)
                .tint(.red)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
        .environmentObject(AddressesController.shared)
        .environmentObject(AddressesViewModel.shared)
}
