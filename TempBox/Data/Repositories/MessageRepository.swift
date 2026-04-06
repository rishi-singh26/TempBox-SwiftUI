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

    /// Matches existing messages by `remoteId`, updates their mutable fields,
    /// inserts new ones, and retains local messages missing from the latest API payload
    /// by marking them as `isRemovedFromRemote = true`.
    /// Returns all active and remotely removed messages for the address.
    func upsert(_ apiMessages: [APIMessage], for address: Address) -> [Message] {
        let currentMessages = address.messages ?? []
        let apiMessageIds = Set(apiMessages.map(\.id))
        var result: [Message] = []

        for apiMsg in apiMessages {
            if let existing = currentMessages.first(where: { $0.remoteId == apiMsg.id }) {
                existing.seen = apiMsg.seen
                result.append(existing)
            } else {
                let msg = Message(from: apiMsg)
                msg.address = address
                modelContext.insert(msg)
                result.append(msg)
            }
        }
        
        // Update the `isRemovedFromRemote` flag for messages that are not present in the apiMessages array
        for existing in currentMessages where !apiMessageIds.contains(existing.remoteId) {
            existing.isRemovedFromRemote = true
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
