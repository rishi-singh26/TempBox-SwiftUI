//
//  NotificationService.swift
//  TempBox
//
//  Created by Rishi Singh on 10/05/26.
//

import UserNotifications

@MainActor
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()
    private override init() { super.init() }

    func requestPermission() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
    }

    func send(for message: Message, address: Address) async {
        let content = UNMutableNotificationContent()
        content.title = address.name ?? address.address
        if let fromName = message.fromName, !fromName.isEmpty {
            content.subtitle = "\(fromName) <\(message.fromAddress)>"
        } else {
            content.subtitle = message.fromAddress
        }
        content.body = message.subject
        content.sound = .default
        content.userInfo = ["addressId": address.id, "messageId": message.remoteId]

        let request = UNNotificationRequest(
            identifier: "msg-\(message.remoteId)",
            content: content,
            trigger: nil
        )
        try? await UNUserNotificationCenter.current().add(request)
    }

    // Show banners and play sound even when the app is in the foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
