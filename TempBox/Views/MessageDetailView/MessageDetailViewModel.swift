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
    @Published var showingAttachmentOptions = false
    @Published var downloadedAttachments: [String: AttachmentDownload] = [:] // attachmentId: attachmentDownloadedFile
    @Published var showSaveAttachmentSheet = false
    @Published var isDownloadingTracker: [String: Bool] = [:] // attachmentId: status
    @Published var downloadErrorTracker: [String: String] = [:] // attachmentId: errorMessage
    
    func downloadAttachments(_ message: Message, token: String) async {
        downloadErrorTracker = [:]
        
        updateDownloadTracker(message: message, value: true)
        
        for attachment in message.safeAttachments {
            do {
                let downloaded = try await MailTMService.downloadAttachment(
                    messageId: message.id,
                    attachment: attachment,
                    token: token
                )
                await MainActor.run {
                    downloadedAttachments[attachment.id] = downloaded
                    isDownloadingTracker[attachment.id] = false
                    downloadErrorTracker.removeValue(forKey: attachment.id)
                }
            } catch {
                await MainActor.run {
                    downloadedAttachments.removeValue(forKey: attachment.id)
                    isDownloadingTracker[attachment.id] = false
                    downloadErrorTracker[attachment.id] = error.localizedDescription
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
}
