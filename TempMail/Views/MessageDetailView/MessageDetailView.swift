//
//  MessageDetailView.swift
//  TempMail
//
//  Created by Rishi Singh on 01/05/25.
//

import SwiftUI

struct MessageDetailView: View {
    @EnvironmentObject private var accountsController: AccountsController
    
    let message: Message?
    let account: Account?
        
    var body: some View {
        if let safeMessage = message, let safeAccount = account {
            VStack(alignment: .leading) {
                MessageHeaderView(message: safeMessage)
                Text(safeMessage.data.subject)
                    .font(.title3.bold())
                if let selectedMessage = accountsController.selectedMessage, let html = selectedMessage.data.html?.first {
                    WebView(html: html)
                }
                if accountsController.loadingCompleteMessage {
                    EmptyView()
                }
            }
            .onAppear(perform: {
                accountsController.fetchCompleteMessage(of: safeMessage.data, account: safeAccount)
                accountsController.markMessageAsRead(messageData: safeMessage, account: safeAccount)
            })
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            //        .toolbar {
            //            ToolbarItemGroup {
            //                Button {
            //                    if let selectedMessage = dataController.selectedMessage, let html = selectedMessage.data.html?.first {
            //                        guard let data = ShareService().createPDF(html: html) else { return }
            //                        guard let pdf = PDFDocument(data: data) else { return }
            //                        print(pdf)
            //                        let result = ShareLink(item: pdf, preview: SharePreview("PDF"))
            //                    }
            //                } label: {
            //                    Label("Share", systemImage: "square.and.arrow.up")
            //                }
            //                Button(role: .destructive) {
            //                    dataController.deleteMessage(message: message, account: account)
            //                } label: {
            //                    Label("Delete", systemImage: "trash")
            //                }
            //            }
            //        }
        } else {
            Text("No message selected")
        }
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
