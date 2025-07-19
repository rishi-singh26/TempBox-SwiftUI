//
//  ShareMessageView.swift
//  TempBox
//
//  Created by Rishi Singh on 19/07/25.
//

import SwiftUI

struct ShareMessageView: View {
    @EnvironmentObject private var addressesController: AddressesController
    @EnvironmentObject private var messageDetailController: MessageDetailViewModel
    @EnvironmentObject private var webViewController: WebViewController
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Group {
#if os(iOS)
            IOSView()
#elseif os(macOS)
            MacOSView()
#endif
        }
        .onAppear(perform: getMessageData)
        .onDisappear(perform: messageDetailController.resetMessageData)
        .background(content: {
            if messageDetailController.showEMLExporter {
                EmptyView()
                    .foregroundStyle(.background)
                    .fileExporter(
                        isPresented: $messageDetailController.showEMLExporter,
                        document: MyFileDocument(data: messageDetailController.messageEMLData),
                        contentType: .data,
                        defaultFilename: getFileNameFrom(ext: ".eml")
                    ) { result in
                        // messageDetailController.resetMessageData()
                    }
            }
            if messageDetailController.showPDFExporter {
                EmptyView()
                    .fileExporter(
                        isPresented: $messageDetailController.showPDFExporter,
                        document: MyFileDocument(data: messageDetailController.messagePDFData),
                        contentType: .data,
                        defaultFilename: getFileNameFrom(ext: ".pdf")
                    ) { result in
                        // messageDetailController.resetMessageData()
                    }
            }
        })
    }
    
#if os(iOS)
    @ViewBuilder
    private func IOSView() -> some View {
        NavigationView {
            List {
                Section(header: Text("Share as .eml")) {
                    Button {
                        messageDetailController.showEMLExporter = true
                    } label: {
                        Label("Save .eml file", systemImage: "square.and.arrow.down")
                    }
                    .help("Save as a email file")
                    .buttonStyle(.plain)
                    .disabled(messageDetailController.isLoadingMessageData)
                    
                    ShareLink(item: messageDetailController.messageEMLURL ?? URL.temporaryDirectory) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .help("Share .eml file")
                    .buttonStyle(.plain)
                    .disabled(messageDetailController.messageEMLURL == nil)
                }
                Section(header: Text("Share as .pdf")) {
                    Button {
                        messageDetailController.showPDFExporter = true
                    } label: {
                        Label("Save .pdf file", systemImage: "square.and.arrow.down")
                    }
                    .help("Save as a pdf file")
                    .buttonStyle(.plain)
                    .disabled(messageDetailController.isLoadingMessageData)
                    
                    ShareLink(item: messageDetailController.messagePDFURL ?? URL.temporaryDirectory) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .help("Share .pdf file")
                    .buttonStyle(.plain)
                    .disabled(messageDetailController.messagePDFURL == nil)
                }
            }
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if messageDetailController.isLoadingMessageData {
                    ToolbarItem(placement: .cancellationAction) {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        messageDetailController.resetMessageData()
                        dismiss()
                    }
                }
            }
        }
    }
#endif
    
#if os(macOS)
    @ViewBuilder
    private func MacOSView() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Share")
                    .font(.title2.bold())
                Spacer()
                if messageDetailController.isLoadingMessageData {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            .padding([.horizontal, .top])
            .padding(.bottom, 8)
            ScrollView {
                MacCustomSection(header: "Share as .eml") {
                    HStack {
                        Label("Save as .eml", systemImage: "square.and.arrow.down")
                        Spacer()
                        Button {
                            messageDetailController.showEMLExporter = true
                        } label: {
                            Text("Save .eml file")
                        }
                        .help("Save as a email file")
                        .disabled(messageDetailController.isLoadingMessageData)
                    }
                    Divider()
                    HStack {
                        Label("Share as .eml", systemImage: "square.and.arrow.up")
                        Spacer()
                        ShareLink(item: messageDetailController.messageEMLURL ?? URL.temporaryDirectory) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .help("Share .eml file")
                        .disabled(messageDetailController.messageEMLURL == nil)
                    }
                }
                .listRowSeparator(.hidden)
                MacCustomSection(header: "Share as .pdf") {
                    HStack {
                        Label("Save as .pdf", systemImage: "square.and.arrow.down")
                        Spacer()
                        Button {
                            messageDetailController.showPDFExporter = true
                        } label: {
                            Text("Save .pdf file")
                        }
                        .help("Save as a pdf file")
                        .disabled(messageDetailController.isLoadingMessageData)
                    }
                    Divider()
                    HStack {
                        Label("Share as .pdf", systemImage: "square.and.arrow.up")
                        Spacer()
                        ShareLink(item: messageDetailController.messagePDFURL ?? URL.temporaryDirectory) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .help("Share .pdf file")
                        .disabled(messageDetailController.messagePDFURL == nil)
                    }
                }
                .listRowSeparator(.hidden)
            }
        }
        .frame(width: 400, height: 310)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
#endif
    
    private func getMessageData() {
        Task {
            if let message = addressesController.selectedMessage, let address = addressesController.selectedAddress {
                messageDetailController.isLoadingMessageData = true
                defer { messageDetailController.isLoadingMessageData = false }
                
                do {
                    if let safeData: Data = await addressesController.downloadMessageResource(message: message, address: address) {
                        messageDetailController.messageEMLData = safeData
                        
                        let fileUrl = URL.temporaryDirectory.appending(path: getFileNameFrom(ext: ".eml"))
                        try safeData.write(to: fileUrl)
                    
                        messageDetailController.messageEMLURL = fileUrl
                    }
                    
                    if let pdfData = try await webViewController.saveAsPDF() {
                        messageDetailController.messagePDFData = pdfData
                        
                        let fileUrl = URL.temporaryDirectory.appending(path: getFileNameFrom(ext: ".pdf"))
                        try pdfData.write(to: fileUrl)
                    
                        messageDetailController.messagePDFURL = fileUrl
                    }
                } catch {
                    messageDetailController.shareFileError = error.localizedDescription
                }
            }
        }
    }
    
    private func getFileNameFrom(ext: String) -> String {
        if let message = addressesController.selectedMessage, !message.subject.isEmpty {
            return "\(message.subject)\(ext)"
        }
        return "message\(ext)"
    }
}

#Preview {
    ShareMessageView()
}
