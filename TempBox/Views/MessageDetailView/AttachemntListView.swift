//
//  AttachemntListView.swift
//  TempBox
//
//  Created by Rishi Singh on 13/06/25.
//

import SwiftUI
import UniformTypeIdentifiers
import QuickLook
import PDFKit

struct AttachemntListView: View {
    @EnvironmentObject private var addressesController: AddressesController
    @EnvironmentObject private var mdController: MessageDetailViewModel
    
    @Environment(\.dismiss) var dismiss
    
    var address: Address
    var message: Message
    var body: some View {
        Group {
            if let selectedMessage = addressesController.selectedCompleteMessage, selectedMessage.id == message.id, let token = address.token {
#if os(iOS)
                IOSView(message: selectedMessage)
                    .onAppear {
                        Task {
                            await mdController.downloadAttachments(selectedMessage, token: token)
                        }
                    }
#elseif os(macOS)
                MacOSView(message: selectedMessage)
                    .onAppear {
                        Task {
                            await mdController.downloadAttachments(selectedMessage, token: token)
                        }
                    }
#endif
            } else {
                List {
                    Text("No Attachment Available")
                }
            }
        }
        .onDisappear {
            mdController.clearAttachmentData()
        }
    }
    
#if os(iOS)
    @ViewBuilder
    func IOSView(message: Message) -> some View {
        NavigationView {
            List(message.attachments ?? []) { attachment in
                NavigationLink {
                    if let downloadedAtchmnt = mdController.downloadedAttachments[attachment.id] {
                        PreviewView(attachment: downloadedAtchmnt)
                    } else {
                        Text("Select an attachment")
                    }
                } label: {
                    HStack {
                        Label(attachment.filename, systemImage: attachment.iconForAttachment)
                        Spacer()
                        if mdController.isDownloadingTracker[attachment.id] == true {
                            ProgressView()
                                .controlSize(.small)
                        }
                        if mdController.downloadErrorTracker[attachment.id] != nil {
                            Image(systemName: "info.triangle.fill")
                        }
                    }
                }
            }
            .navigationTitle("Attachments")
            .toolbar {
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
    func MacOSView(message: Message) -> some View {
        NavigationSplitView {
            List(message.safeAttachments, selection: Binding(get: {
                mdController.selectedAttachment
            }, set: { newVal in
                DispatchQueue.main.async {
                    mdController.selectedAttachment = newVal
                }
            })
            ) { attachment in
                NavigationLink(value: attachment) {
                    AttachmentTile(attachment: attachment)
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Attachments")
        } detail: {
            if let selectedAttachment = mdController.selectedAttachment, let downloadedAtchmnt = mdController.downloadedAttachments[selectedAttachment.id] {
                QuicklookPreview(urls: [downloadedAtchmnt.fileURL])
                    .fileExporter(
                        isPresented: $mdController.showSaveAttachmentSheet,
                        document: MyFileDocument(data: downloadedAtchmnt.fileData),
                        contentType: .data,
                        defaultFilename: downloadedAtchmnt.filename
                    ) { result in
                        handleFileSaveResult(result)
                    }
            } else  {
                Text("Select an attachment")
            }
        }
        .frame(minWidth: 900, minHeight: 600)
    }
#endif
    
    private func handleFileSaveResult(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            print("File saved successfully to: \(url.lastPathComponent)")
        case .failure(let error):
            print("Error saving file: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AddressesController.shared)
        .environmentObject(AddressesViewModel.shared)
}

#if os(macOS)
struct AttachmentTile: View {
    @EnvironmentObject private var mdController: MessageDetailViewModel
    
    var attachment: Attachment
    
    var body: some View {
        HStack {
            Label(attachment.filename, systemImage: attachment.iconForAttachment)
            Spacer()
            if mdController.isDownloadingTracker[attachment.id] == true {
                ProgressView()
                    .controlSize(.small)
            } else if mdController.downloadErrorTracker[attachment.id] != nil {
                Image(systemName: "info.triangle.fill")
            } else if mdController.downloadedAttachments[attachment.id]?.attachmentId == attachment.id {
                Menu {
                    ShareLink(item: mdController.downloadedAttachments[attachment.id]!.fileURL) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    Button {
                        mdController.showSaveAttachmentSheet.toggle()
                    } label: {
                        Label("Save", systemImage: "square.and.arrow.down")
                    }
                    .disabled(mdController.selectedAttachment == nil)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .buttonStyle(.plain)
            } else {
                Text("")
            }
        }
    }
}
#endif

#if os(iOS)
struct PreviewView: View {
    @EnvironmentObject private var mdController: MessageDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    var attachment: AttachmentDownload
    
    var body: some View {
            QuicklookPreview(urls: [attachment.fileURL])
                .navigationTitle(attachment.filename)
                .navigationBarTitleDisplayMode(.inline)
                .fileExporter(
                    isPresented: $mdController.showSaveAttachmentSheet,
                    document: MyFileDocument(data: attachment.fileData),
                    contentType: .data,
                    defaultFilename: attachment.filename
                ) { result in
                    handleFileSaveResult(result)
                }
                .toolbar {
                    ToolbarTitleMenu {
                        ShareLink(item: attachment.fileURL) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        Button {
                            mdController.showSaveAttachmentSheet.toggle()
                        } label: {
                            Label("Save", systemImage: "square.and.arrow.down")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            attachment.cleanupTemporaryFile()
                            dismiss()
                        } label: {
                            Text("Done")
                                .font(.headline)
                        }
                    }
                }
    }
    
    private func handleFileSaveResult(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            print("File saved successfully to: \(url.lastPathComponent)")
        case .failure(let error):
            print("Error saving file: \(error.localizedDescription)")
        }
    }
}
#endif
