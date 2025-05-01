//
//  MessageDetailView.swift
//  TempMail
//
//  Created by Rishi Singh on 01/05/25.
//

import SwiftUI

struct MessageDetailView: View {
    @EnvironmentObject private var accountsController: AccountsController
    
    let message: Message
    let account: Account
        
    var body: some View {
        VStack(alignment: .leading) {
            MessageHeaderView(message: message)
            Text(message.data.subject)
                .font(.title3.bold())
            if let selectedMessage = accountsController.selectedCompleteMessage, let html = selectedMessage.html?.first {
                WebView(html: html)
            }
            if accountsController.loadingCompleteMessage {
                EmptyView()
            }
        }
        .onAppear(perform: {
            accountsController.fetchCompleteMessage(of: message.data, account: account)
            accountsController.markMessageAsRead(messageData: message, account: account)
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
        .environmentObject(AccountsController.shared)
}
