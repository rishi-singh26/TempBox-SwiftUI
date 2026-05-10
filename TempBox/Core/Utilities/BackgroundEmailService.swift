//
//  BackgroundEmailService.swift
//  TempBox
//
//  Created by Rishi Singh on 10/05/26.
//

#if os(iOS)
import BackgroundTasks
import SwiftData
import UserNotifications

struct BackgroundEmailService {
    static let taskIdentifier = "com.rishi.TempMail.fetchEmails"

    static func register(modelContainer: ModelContainer) {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: taskIdentifier,
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else { return }
            let emailTask = Task { @MainActor in
                await fetchAll(modelContainer: modelContainer)
            }
            refreshTask.expirationHandler = {
                emailTask.cancel()
                refreshTask.setTaskCompleted(success: false)
            }
            Task {
                await emailTask.value
                refreshTask.setTaskCompleted(success: true)
                scheduleBackgroundFetch()
            }
        }
    }

    static func scheduleBackgroundFetch() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    // Uses a fresh ModelContext so it works safely in background and terminated states.
    // Body-fetching is intentionally skipped here to stay within the background time budget.
    @MainActor
    private static func fetchAll(modelContainer: ModelContainer) async {
        let ctx = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<Address>(
            predicate: #Predicate { !$0.isArchived && !$0.isDeleted }
        )
        guard let addresses = try? ctx.fetch(descriptor) else { return }
        let repo = MessageRepository(modelContext: ctx)

        for address in addresses {
            guard let token = address.token, !token.isEmpty else { continue }
            let existingIds = Set((address.messages ?? []).map(\.remoteId))
            do {
                let apiMessages = try await MailTMNetworkService.shared.fetchMessages(token: token, page: 1)
                _ = repo.upsert(apiMessages, for: address)
                repo.save()
                let newMessages = (address.messages ?? []).filter {
                    !existingIds.contains($0.remoteId)
                }
                for msg in newMessages {
                    await NotificationService.shared.send(for: msg, address: address)
                }
            } catch {
                // Move on to the next address on failure
            }
        }
    }
}
#endif
