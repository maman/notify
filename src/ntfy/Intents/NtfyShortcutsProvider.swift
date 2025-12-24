//
//  NtfyShortcutsProvider.swift
//  ntfy
//
//  Created by Claude on 24/12/24.
//

import AppIntents

/// Provides pre-configured App Shortcuts for Siri and the Shortcuts app
struct NtfyShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        // 1. Get Unread Count
        AppShortcut(
            intent: GetUnreadCountIntent(),
            phrases: [
                "How many unread in \(.applicationName)",
                "Check \(.applicationName) notifications",
                "Show \(.applicationName) unread count",
                "Get \(.applicationName) notification count"
            ],
            shortTitle: "Unread Count",
            systemImageName: "bell.badge"
        )

        // 2. Mark All as Read
        AppShortcut(
            intent: MarkAllMessagesAsReadIntent(),
            phrases: [
                "Mark all \(.applicationName) as read",
                "Clear \(.applicationName) notifications",
                "Read all \(.applicationName) messages"
            ],
            shortTitle: "Mark All Read",
            systemImageName: "checkmark.circle"
        )

        // 3. Subscribe to Topic
        AppShortcut(
            intent: SubscribeToTopicIntent(),
            phrases: [
                "Subscribe to topic in \(.applicationName)",
                "Add topic to \(.applicationName)",
                "Follow topic with \(.applicationName)"
            ],
            shortTitle: "Subscribe",
            systemImageName: "plus.circle"
        )

        // 4. Open Topic
        AppShortcut(
            intent: OpenTopicIntent(),
            phrases: [
                "Open \(\.$topic) in \(.applicationName)",
                "Show \(\.$topic) in \(.applicationName)"
            ],
            shortTitle: "Open Topic",
            systemImageName: "arrow.up.forward.app"
        )
    }

    static var shortcutTileColor: ShortcutTileColor {
        .blue
    }
}
