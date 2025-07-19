//
//  MessageDetailViewModel.swift
//  TempBox
//
//  Created by Rishi Singh on 13/06/25.
//

import Foundation

@MainActor
class MessageDetailViewModel: ObservableObject {
    // MARK: - MessageDetail view properties
    @Published var showMessageInfoSheet = false
    @Published var showAttachmentsSheet = false
    
    // MARK: - Attachment View navigation properties
    @Published var selectedAttachment: Attachment? = nil
    
    // MARK: - Attachment view properties
    @Published var showShareAttachmentSheet = false
    
    @Published var showSaveAttachmentSheet = false
    /// Will be used on macOS only, will be set when user selects save option from the attachments list
    @Published var selectedAttachmentForExport: AttachmentDownload? = nil
    
    @Published var downloadedAttachments: [String: AttachmentDownload] = [:] // attachmentId: attachmentDownloadedFile
    @Published var isDownloadingTracker: [String: Bool] = [:] // attachmentId: status
    @Published var downloadErrorTracker: [String: String] = [:] // attachmentId: errorMessage
    
    // Share email to .eml and .pdf properties
    @Published var messageEMLData: Data = Data()
    @Published var messagePDFData: Data = Data()
    @Published var messageEMLURL: URL? = nil
    @Published var messagePDFURL: URL? = nil
    @Published var shareFileError: String? = nil
    @Published var showShareEmailSheet: Bool = false
    @Published var showEMLExporter: Bool = false
    @Published var showPDFExporter: Bool = false
    @Published var isLoadingMessageData: Bool = true
    
    func downloadAttachments(_ message: Message, token: String) async {
        downloadErrorTracker = [:]
        updateDownloadTracker(message: message, value: true)

        await withTaskGroup(of: Void.self) { group in
            for attachment in message.safeAttachments {
                // Set downloading state
                await MainActor.run {
                    isDownloadingTracker[attachment.id] = true
                }

                group.addTask {
                    do {
                        let downloaded = try await MailTMService.downloadAttachment(
                            messageId: message.id,
                            attachment: attachment,
                            token: token
                        )
                        await MainActor.run {
                            self.downloadedAttachments[attachment.id] = downloaded
                            self.isDownloadingTracker[attachment.id] = false
                            self.downloadErrorTracker.removeValue(forKey: attachment.id)
                        }
                    } catch {
                        await MainActor.run {
                            self.downloadedAttachments.removeValue(forKey: attachment.id)
                            self.isDownloadingTracker[attachment.id] = false
                            self.downloadErrorTracker[attachment.id] = error.localizedDescription
                        }
                    }
                }
            }
        }
    }
    
    func updateDownloadTracker(message: Message, value: Bool) {
        message.safeAttachments.forEach { a in
            isDownloadingTracker[a.id] = value
        }
    }
    
    func clearAttachmentData() {
        downloadedAttachments.values.forEach { a in
            a.cleanupTemporaryFile()
        }
        downloadedAttachments = [:]
        isDownloadingTracker = [:]
        downloadErrorTracker = [:]
        selectedAttachment = nil
        showSaveAttachmentSheet = false
    }
    
    func resetMessageData() {
        messageEMLData = Data()
        messagePDFData = Data()
        messageEMLURL = nil
        messagePDFURL = nil
        shareFileError = nil
        isLoadingMessageData = false
    }
}
