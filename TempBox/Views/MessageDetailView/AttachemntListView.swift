//
//  AttachemntListView.swift
//  TempBox
//
//  Created by Rishi Singh on 13/06/25.
//

import SwiftUI

struct AttachemntListView: View {
    @EnvironmentObject private var addressesController: AddressesController
    @EnvironmentObject private var mdController: MessageDetailViewModel
    
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
}

#if os(macOS)
struct MacOSView: View {
    @EnvironmentObject private var mdController: MessageDetailViewModel
    
    var message: Message
    
    var body: some View {
        let selectionBinding = Binding(
            get: { mdController.selectedAttachment },
            set: { newVal in
                DispatchQueue.main.async {
                    mdController.selectedAttachment = newVal
                }
            }
        )
        NavigationSplitView {
            List(message.safeAttachments, selection: selectionBinding) { attachment in
                NavigationLink(value: attachment) {
                    AttachmentTileMacOS(attachment: attachment)
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Attachments")
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            .fileExporter(
                isPresented: $mdController.showSaveAttachmentSheet,
                document: MyFileDocument(data: mdController.selectedAttachmentForExport?.fileData ?? Data()),
                contentType: .data,
                defaultFilename: mdController.selectedAttachmentForExport?.filename
            ) { result in
                handleFileSaveResult(result)
            }
        } detail: {
            if let selectedAttachment = mdController.selectedAttachment, let downloadedAtchmnt = mdController.downloadedAttachments[selectedAttachment.id] {
                QuicklookPreview(urls: [downloadedAtchmnt.fileURL])
            } else  {
                Text("Select an attachment")
            }
        }
        .frame(minWidth: 900, minHeight: 600)
    }
    
    private func handleFileSaveResult(_ result: Result<URL, Error>) {
        // Reset select attachment for export value
        mdController.selectedAttachmentForExport = nil
        
        switch result {
        case .success(let url):
            print("File saved successfully to: \(url.lastPathComponent)")
        case .failure(let error):
            print("Error saving file: \(error.localizedDescription)")
        }
    }
}

struct AttachmentTileMacOS: View {
    @EnvironmentObject private var mdController: MessageDetailViewModel
    
    var attachment: Attachment
    
    var body: some View {
        HStack {
            Label {
                VStack(alignment: .leading) {
                    Text(attachment.filename)
                    Text(attachment.sizeString)
                        .font(.caption)
                }
            } icon: {
                Image(systemName: attachment.iconForAttachment)
            }
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
                    .help("Share attachment")
                    Button {
                        if let safeAttachmentData = mdController.downloadedAttachments[attachment.id] {
                            mdController.selectedAttachmentForExport = safeAttachmentData
                            mdController.showSaveAttachmentSheet = true
                        }
                    } label: {
                        Label("Save", systemImage: "square.and.arrow.down")
                    }
                    .help("Save attachment")
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
struct IOSView: View {
    @EnvironmentObject private var mdController: MessageDetailViewModel
    @Environment(\.dismiss) var dismiss
    
    var message: Message
    
    var body: some View {
        NavigationView {
            List(message.attachments ?? []) { attachment in
                NavigationLink {
                    if let downloadedAtchmnt = mdController.downloadedAttachments[attachment.id] {
                        PreviewView(attachment: downloadedAtchmnt)
                    } else {
                        Text("Select an attachment")
                    }
                } label: {
                    AttachmentTileIOS(attachment: attachment)
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
}

struct AttachmentTileIOS: View {
    @EnvironmentObject private var mdController: MessageDetailViewModel
    
    var attachment: Attachment
    
    var body: some View {
        HStack {
            Label {
                VStack(alignment: .leading) {
                    Text(attachment.filename)
                    Text(attachment.sizeString)
                        .font(.caption)
                }
            } icon: {
                Image(systemName: attachment.iconForAttachment)
            }
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

struct PreviewView: View {
    @EnvironmentObject private var mdController: MessageDetailViewModel
    
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
                .shareSheet(
                    isPresented: $mdController.showShareAttachmentSheet,
                    items: [attachment.fileURL],
                    excludedActivityTypes: [
                        // iOS-specific exclusions (ignored on macOS)
                        UIActivity.ActivityType.addToReadingList,
                        UIActivity.ActivityType.assignToContact
                    ]
                )
                .toolbar {
                    ToolbarTitleMenu {
                        Button {
                            mdController.showShareAttachmentSheet = true
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .help("Share attachment")
                        Button {
                            mdController.showSaveAttachmentSheet.toggle()
                        } label: {
                            Label("Save", systemImage: "square.and.arrow.down")
                        }
                        .help("Save attachment")
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

#Preview {
    ContentView()
        .environmentObject(AddressesController.shared)
        .environmentObject(AddressesViewModel.shared)
}
