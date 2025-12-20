//
//  NotificationService.swift
//  ntfy
//
//  Created by Achmad Mahardi on 19/12/25.
//

import Foundation
import UserNotifications
import SwiftData

/// Notification posted when user clicks a notification to open a topic
extension Notification.Name {
    static let openTopic = Notification.Name("openTopic")
}

/// Shared state for notification handling (must be accessible from delegate)
@MainActor
final class NotificationState {
    static let shared = NotificationState()
    var modelContainer: ModelContainer?

    private init() {}

    func openTopic(topicId: String, messageId: String) {
        // Post notification to open the topic window and highlight message
        NotificationCenter.default.post(
            name: .openTopic,
            object: nil,
            userInfo: ["topicId": topicId, "messageId": messageId]
        )
    }

    func markMessageAsRead(messageId: String) {
        guard let container = modelContainer else {
            print("ModelContainer not set - cannot mark message as read")
            return
        }

        let context = container.mainContext
        let predicate = #Predicate<Message> { $0.id == messageId }
        let descriptor = FetchDescriptor<Message>(predicate: predicate)

        do {
            let messages = try context.fetch(descriptor)
            if let message = messages.first {
                message.isRead = true
                try context.save()
                print("Marked message \(messageId) as read from notification")
            }
        } catch {
            print("Failed to mark message as read: \(error)")
        }
    }
}

actor NotificationService {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()

    private init() {
        Task {
            await setupCategories()
            await setupDelegate()
        }
    }

    @MainActor
    private func setupDelegate() {
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }

    func setModelContainer(_ container: ModelContainer) async {
        await MainActor.run {
            NotificationState.shared.modelContainer = container
        }
    }

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("Failed to request notification permission: \(error)")
            return false
        }
    }

    func checkPermission() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    // MARK: - Notifications

    func showNotification(for message: NtfyMessage, topicID: UUID, topicDisplayName: String) {
        let content = UNMutableNotificationContent()
        content.title = message.title ?? topicDisplayName
        content.body = message.message ?? ""
        content.sound = priorityToSound(message.priority ?? 3)
        content.userInfo = [
            "topicId": topicID.uuidString,
            "messageId": message.id
        ]

        // Set thread identifier for grouping
        content.threadIdentifier = topicID.uuidString

        // Add category for actions if message has actions
        if let actions = message.actions, !actions.isEmpty {
            content.categoryIdentifier = "NTFY_MESSAGE_WITH_ACTIONS"
        } else {
            content.categoryIdentifier = "NTFY_MESSAGE"
        }

        let request = UNNotificationRequest(
            identifier: message.id,
            content: content,
            trigger: nil
        )

        center.add(request) { error in
            if let error = error {
                print("Failed to show notification: \(error)")
            }
        }
    }

    func clearNotifications(for topicID: UUID) {
        center.removeDeliveredNotifications(withIdentifiers: [topicID.uuidString])
    }

    func clearAllNotifications() {
        center.removeAllDeliveredNotifications()
    }

    // MARK: - Private

    private func setupCategories() {
        let markReadAction = UNNotificationAction(
            identifier: "MARK_READ",
            title: String(localized: "Mark as Read"),
            options: []
        )

        let categoryWithActions = UNNotificationCategory(
            identifier: "NTFY_MESSAGE_WITH_ACTIONS",
            actions: [markReadAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        let category = UNNotificationCategory(
            identifier: "NTFY_MESSAGE",
            actions: [markReadAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        center.setNotificationCategories([category, categoryWithActions])
    }

    private func priorityToSound(_ priority: Int) -> UNNotificationSound {
        switch priority {
        case 5:
            return .defaultCritical
        case 4:
            return .default
        case 1, 2:
            return UNNotificationSound.default
        default:
            return .default
        }
    }
}

// MARK: - Notification Delegate

/// Retained delegate instance (must persist for notification callbacks)
private let notificationDelegate = NotificationDelegate()

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        switch response.actionIdentifier {
        case "MARK_READ":
            // Handle mark as read action
            if let messageId = userInfo["messageId"] as? String {
                Task { @MainActor in
                    NotificationState.shared.markMessageAsRead(messageId: messageId)
                }
            }

        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification itself - mark as read and open topic
            if let messageId = userInfo["messageId"] as? String {
                Task { @MainActor in
                    NotificationState.shared.markMessageAsRead(messageId: messageId)
                }
            }
            if let topicId = userInfo["topicId"] as? String,
               let messageId = userInfo["messageId"] as? String {
                Task { @MainActor in
                    NotificationState.shared.openTopic(topicId: topicId, messageId: messageId)
                }
            }

        default:
            break
        }

        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
}
