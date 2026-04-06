//
//  MessageService.swift
//  TempBox
//
//  Created by Rishi Singh on 06/04/26.
//

import Foundation

@MainActor
final class MessageService: MessageServiceProtocol {
    private let repository: any MessageRepositoryProtocol
    private let networkService: any MailTMNetworkServiceProtocol

    init(repository: any MessageRepositoryProtocol, networkService: any MailTMNetworkServiceProtocol) {
        self.repository = repository
        self.networkService = networkService
    }

    // MARK: - Fetch

    func fetchMessages(for address: Address) async throws {
        guard let token = address.token, !token.isEmpty else { return }
        let apiMessages = try await networkService.fetchMessages(token: token, page: 1)
        let result = repository.upsert(apiMessages, for: address)

        // Fetch full body for new messages (background, non-throwing)
        let newMessages = result.filter { $0.html == nil }
        await fetchCompleteMessages(for: newMessages, address: address)
    }

    func fetchCompleteMessages(for messages: [Message], address: Address) async {
        await withTaskGroup(of: Void.self) { group in
            for message in messages where !address.isArchived {
                group.addTask {
                    await self.fetchCompleteMessage(of: message)
                }
            }
        }
    }

    func fetchCompleteMessage(of message: Message) async {
        guard message.html == nil else { return }
        guard let token = message.address?.token, !token.isEmpty else { return }

        do {
            let completeMessage = try await networkService.fetchMessage(id: message.remoteId, token: token)
            message.update(with: completeMessage)
            repository.save()
        } catch let decodingError as DecodingError {
            switch decodingError {
            case .keyNotFound(let key, let ctx):
                print("Key '\(key)' not found: \(ctx.debugDescription)")
            case .typeMismatch(let type, let ctx):
                print("Type '\(type)' mismatch: \(ctx.debugDescription)")
            case .valueNotFound(let type, let ctx):
                print("Value '\(type)' not found: \(ctx.debugDescription)")
            case .dataCorrupted(let ctx):
                print("Data corrupted: \(ctx.debugDescription)")
            default:
                print("Decoding error: \(decodingError.localizedDescription)")
            }
        } catch {
            print("MessageService.fetchCompleteMessage error: \(error.localizedDescription)")
        }
    }

    // MARK: - Update

    func updateSeenStatus(_ message: Message) async {
        guard !message.isRemovedFromRemote else { return }
        guard let token = message.address?.token, !token.isEmpty else { return }
        do {
            _ = try await networkService.updateMessageSeenStatus(
                id: message.remoteId,
                token: token,
                seen: !message.seen
            )
            message.seen = !message.seen
        } catch {
            if case MailTMError.notFound = error {
                // Update the status in SwiftData if the message has been deleted from mail.tm server
                message.seen = !message.seen
            } else {
                print("MessageService.updateSeenStatus error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Delete

    func deleteMessage(_ message: Message) async {
        guard let token = message.address?.token, !token.isEmpty else { return }
        do {
            try await networkService.deleteMessage(id: message.remoteId, token: token)
            repository.delete(message)
        } catch {
            print("MessageService.deleteMessage error: \(error.localizedDescription)")
        }
    }

    // MARK: - Download

    func downloadMessageResource(message: Message, address: Address) async -> Data? {
        guard let token = address.token, !token.isEmpty else { return nil }
        do {
            return try await networkService.downloadMessageEML(id: message.remoteId, token: token)
        } catch {
            print("MessageService.downloadMessageResource error: \(error.localizedDescription)")
            return nil
        }
    }

    func downloadAttachments(_ message: Message, token: String) async -> [String: AttachmentDownload] {
        var result: [String: AttachmentDownload] = [:]

        await withTaskGroup(of: (String, AttachmentDownload?).self) { group in
            for attachment in message.safeAttachments {
                group.addTask {
                    do {
                        let downloaded = try await self.networkService.downloadAttachment(
                            messageId: message.remoteId,
                            attachment: attachment,
                            token: token
                        )
                        return (attachment.id, downloaded)
                    } catch {
                        return (attachment.id, nil)
                    }
                }
            }

            for await (id, download) in group {
                if let download = download {
                    result[id] = download
                }
            }
        }

        return result
    }
}
