//
//  MessageRepositoryProtocol.swift
//  TempBox
//
//  Created by Rishi Singh on 06/04/26.
//

import Foundation

@MainActor
protocol MessageRepositoryProtocol {
    /// Upserts API messages into SwiftData for the given address.
    /// Returns the resulting array of Message model objects.
    func upsert(_ apiMessages: [APIMessage], for address: Address) -> [Message]
    func delete(_ message: Message)
    func save()
}
