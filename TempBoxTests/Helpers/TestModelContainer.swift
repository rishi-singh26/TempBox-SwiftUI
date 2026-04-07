//
//  TestModelContainer.swift
//  TempBoxTests
//
//  Creates a fully in-memory SwiftData ModelContainer using the latest V41 schema.
//  No migrations are run — tests always start from a clean empty store.
//

import Foundation
import SwiftData
@testable import TempBox

/// Returns a fresh in-memory ModelContainer containing Address, Folder, and Message.
/// Each call produces an independent store; no data leaks between tests.
@MainActor
func makeTestModelContainer() throws -> ModelContainer {
    let schema = Schema([Address.self, Folder.self, Message.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(for: schema, configurations: [config])
}

// MARK: - Shared model factories

/// Creates an Address suitable for insertion into a test container.
func makeAddress(
    id: String = "addr-1",
    address: String? = nil,
    name: String? = nil,
    isDeleted: Bool = false,
    isArchived: Bool = false,
    token: String = "tok-test",
    createdAt: Date = Date()
) -> Address {
    Address(
        id: id,
        name: name,
        address: address ?? "\(id)@test.io",
        quota: 40_000_000,
        used: 0,
        isArchived: isArchived,
        isDeleted: isDeleted,
        createdAt: createdAt,
        updatedAt: createdAt,
        token: token,
        password: "pass123"
    )
}

/// Creates an APIMessage suitable for use in repository upsert tests.
func makeAPIMessage(
    id: String = "msg-1",
    accountId: String = "acct-1",
    seen: Bool = false,
    subject: String = "Test Subject"
) -> APIMessage {
    APIMessage(
        id: id,
        accountId: accountId,
        msgid: "<\(id)@test.io>",
        from: EmailAddress(name: "Sender", address: "from@test.io"),
        to: [EmailAddress(name: nil, address: "to@test.io")],
        cc: nil,
        bcc: nil,
        subject: subject,
        intro: nil,
        text: nil,
        html: nil,
        seen: seen,
        flagged: nil,
        isDeleted: false,
        verifications: nil,
        retention: nil,
        retentionDate: nil,
        hasAttachments: false,
        attachments: nil,
        size: 512,
        downloadUrl: "/messages/\(id)/download",
        sourceUrl: "/sources/\(id)",
        createdAt: "2024-01-15T10:00:00Z",
        updatedAt: "2024-01-15T10:00:00Z"
    )
}
