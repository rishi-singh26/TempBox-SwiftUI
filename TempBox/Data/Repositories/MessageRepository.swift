//
//  MessageRepository.swift
//  TempBox
//
//  Created by Rishi Singh on 06/04/26.
//

import SwiftData

@MainActor
final class MessageRepository: MessageRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Upserts API messages into SwiftData for the given address.
    /// Matches existing messages by remoteId, updates seen status on existing ones,
    /// inserts new ones. Returns the resulting Message array.
    func upsert(_ apiMessages: [APIMessage], for address: Address) -> [Message] {
        let currentMessages = address.messages ?? []
        var result: [Message] = []

        for apiMsg in apiMessages {
            if let existing = currentMessages.first(where: { $0.remoteId == apiMsg.id }) {
                existing.seen = apiMsg.seen
                result.append(existing)
            } else {
                let msg = Message(api: apiMsg)
                msg.address = address
                modelContext.insert(msg)
                result.append(msg)
            }
        }

        return result
    }

    func delete(_ message: Message) {
        modelContext.delete(message)
    }

    func save() {
        do {
            try modelContext.save()
        } catch {
            print("MessageRepository: failed to save — \(error.localizedDescription)")
        }
    }
}
