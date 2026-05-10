//
//  LiveEmailPoller.swift
//  TempBox
//
//  Created by Rishi Singh on 10/05/26.
//

import Foundation
import SwiftData

@MainActor
final class LiveEmailPoller {
    static let shared = LiveEmailPoller()
    private init() {}

    private var timer: Timer?
    private var messageService: MessageService?
    private var messageRepository: MessageRepository?
    private var modelContext: ModelContext?
    private var isPolling = false
    private let interval: TimeInterval = 30

    func start(modelContext: ModelContext) {
        guard timer == nil else { return }
        self.modelContext = modelContext
        let repo = MessageRepository(modelContext: modelContext)
        self.messageRepository = repo
        self.messageService = MessageService(repository: repo, networkService: MailTMNetworkService.shared)
        timer = Timer.scheduledTimer(
            timeInterval: interval,
            target: self,
            selector: #selector(handleTimer),
            userInfo: nil,
            repeats: true
        )
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        messageService = nil
        messageRepository = nil
        modelContext = nil
        isPolling = false
    }

    @objc private func handleTimer() {
        guard !isPolling,
              let modelContext,
              let messageService,
              let repo = messageRepository else { return }
        isPolling = true
        Task { @MainActor [weak self] in
            defer { self?.isPolling = false }
            await self?.poll(modelContext: modelContext, messageService: messageService, repo: repo)
        }
    }

    private func poll(
        modelContext: ModelContext,
        messageService: MessageService,
        repo: MessageRepository
    ) async {
        let descriptor = FetchDescriptor<Address>(
            predicate: #Predicate { !$0.isArchived && !$0.isDeleted }
        )
        guard let addresses = try? modelContext.fetch(descriptor) else { return }

        await withTaskGroup(of: Void.self) { group in
            for address in addresses {
                group.addTask { @MainActor in
                    guard let token = address.token, !token.isEmpty else { return }
                    _ = token
                    let existingIds = Set((address.messages ?? []).map(\.remoteId))
                    do {
                        try await messageService.fetchMessages(for: address)
                        repo.save()
                        let newMessages = (address.messages ?? []).filter {
                            !existingIds.contains($0.remoteId)
                        }
                        for msg in newMessages {
                            await NotificationService.shared.send(for: msg, address: address)
                        }
                    } catch {
                        // Polling failures are silent
                    }
                }
            }
        }
    }
}
