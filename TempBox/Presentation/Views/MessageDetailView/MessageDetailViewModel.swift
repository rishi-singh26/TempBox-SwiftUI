//
//  MessageDetailViewModel.swift
//  TempBox
//
//  Created by Rishi Singh on 13/06/25.
//

import Foundation
import Observation

@Observable
@MainActor
class MessageDetailViewModel {
    // MARK: - MessageDetail view properties
    var showMessageInfoSheet = false
    var showAttachmentsSheet = false

    // MARK: - Attachment View navigation properties
    var selectedAttachment: Attachment? = nil

    // MARK: - Attachment view properties
    var showShareAttachmentSheet = false

    var showSaveAttachmentSheet = false
    /// Used on macOS only when user selects save option from the attachments list
    var selectedAttachmentForExport: AttachmentDownload? = nil

    var downloadedAttachments: [String: AttachmentDownload] = [:]   // attachmentId: downloadedFile
    var isDownloadingTracker: [String: Bool] = [:]                   // attachmentId: status
    var downloadErrorTracker: [String: String] = [:]                 // attachmentId: errorMessage

    // Share email to .eml and .pdf properties
    var messageEMLData: Data = Data()
    var messagePDFData: Data = Data()
    var messageEMLURL: URL? = nil
    var messagePDFURL: URL? = nil
    var shareFileError: String? = nil
    var showShareEmailSheet: Bool = false
    var showEMLExporter: Bool = false
    var showPDFExporter: Bool = false
    var isLoadingMessageData: Bool = true

    func downloadAttachments(_ message: Message, token: String) async {
        downloadErrorTracker = [:]
        updateDownloadTracker(message: message, value: true)

        await withTaskGroup(of: Void.self) { group in
            for attachment in message.safeAttachments {
                await MainActor.run {
                    isDownloadingTracker[attachment.id] = true
                }

                group.addTask {
                    do {
                        let downloaded = try await MailTMNetworkService.shared.downloadAttachment(
                            messageId: message.remoteId,
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
