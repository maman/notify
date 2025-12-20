//
//  AppState.swift
//  ntfy
//
//  Created by Achmad Mahardi on 19/12/25.
//

import Foundation
import SwiftUI
import SwiftData
import ServiceManagement
import AppKit

@Observable
final class AppState {
    let ntfyService = NtfyService()
    let notificationService = NotificationService.shared
    let keychainService = KeychainService.shared

    /// Selected topic IDs - using Set<UUID> for multi-selection support
    var selectedTopicIds: Set<UUID> = []
    var isShowingNewTopicForm = false

    /// Convenience for single-selection scenarios
    var selectedTopicId: UUID? {
        get { selectedTopicIds.count == 1 ? selectedTopicIds.first : nil }
        set {
            if let id = newValue {
                selectedTopicIds = [id]
            } else {
                selectedTopicIds.removeAll()
            }
        }
    }
    var highlightedMessageId: String?

    // MARK: - Launch at Login

    private var _launchAtLogin: Bool = false

    var launchAtLogin: Bool {
        get { _launchAtLogin }
        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
                _launchAtLogin = newValue
            } catch {
                print("Failed to \(newValue ? "enable" : "disable") launch at login: \(error)")
            }
        }
    }

    private func syncLaunchAtLoginState() {
        _launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    // MARK: - Initialization

    init() {
        syncLaunchAtLoginState()
        // Note: Message handler is set up in MenuBarContentView on app startup
        Task {
            await requestNotificationPermission()
        }
    }

    // MARK: - Dock Visibility

    func showInDock() {
        // Must set policy before activating
        NSApp.setActivationPolicy(.regular)
        // Unhide in case app was hidden
        NSApp.unhide(nil)
        // Activate after policy change - use async to ensure policy takes effect
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func hideFromDock() {
        NSApp.setActivationPolicy(.accessory)
    }

    // MARK: - Topic Management

    func subscribeToAllTopics(_ topics: [Topic]) async {
        for topic in topics {
            await ntfyService.subscribe(to: topic)
        }
    }

    func subscribe(to topic: Topic) async {
        await ntfyService.subscribe(to: topic)
    }

    func unsubscribe(from topic: Topic) async {
        await ntfyService.unsubscribe(from: topic)
    }

    func addTopic(
        name: String,
        serverURL: String,
        username: String?,
        password: String?,
        modelContext: ModelContext
    ) async -> Topic {
        let topic = Topic(
            name: name,
            serverURL: serverURL,
            username: username
        )

        // Store password in keychain if provided
        if let password = password, !password.isEmpty {
            do {
                try keychainService.setPassword(password, for: topic.id)
            } catch {
                print("Failed to store password in keychain for topic \(topic.id): \(error)")
            }
        }

        modelContext.insert(topic)
        do {
            try modelContext.save()
        } catch {
            print("Failed to save topic to database: \(error)")
        }

        // Subscribe to the new topic
        await subscribe(to: topic)

        return topic
    }

    @MainActor
    func deleteTopic(_ topic: Topic, modelContext: ModelContext) async {
        // Unsubscribe first (async operation)
        await unsubscribe(from: topic)

        // Remove password from keychain
        do {
            try keychainService.removePassword(for: topic.id)
        } catch {
            print("Failed to remove password from keychain for topic \(topic.id): \(error)")
        }

        // Delete from database (must be on MainActor for ModelContext safety)
        modelContext.delete(topic)
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete topic from database: \(error)")
        }

        // Clear selection if deleted topic was selected
        selectedTopicIds.remove(topic.id)
    }

    @MainActor
    func deleteTopics(_ topics: [Topic], modelContext: ModelContext) async {
        // Unsubscribe from all topics in parallel for performance
        await withTaskGroup(of: Void.self) { group in
            for topic in topics {
                group.addTask {
                    await self.unsubscribe(from: topic)
                }
            }
        }

        // Perform all ModelContext operations synchronously on MainActor
        for topic in topics {
            // Remove password from keychain
            do {
                try keychainService.removePassword(for: topic.id)
            } catch {
                print("Failed to remove password from keychain for topic \(topic.id): \(error)")
            }

            modelContext.delete(topic)
        }

        do {
            try modelContext.save()
        } catch {
            print("Failed to delete topics from database: \(error)")
        }

        // Clear selection
        selectedTopicIds.removeAll()
    }

    func renameTopic(_ topic: Topic, to newName: String, modelContext: ModelContext) {
        topic.displayName = newName.isEmpty ? nil : newName
        do {
            try modelContext.save()
        } catch {
            print("Failed to save topic rename: \(error)")
        }
    }

    // MARK: - Message Management

    func markAsRead(_ message: Message, modelContext: ModelContext) {
        message.isRead = true
        do {
            try modelContext.save()
        } catch {
            print("Failed to mark message as read: \(error)")
        }
    }

    func markAllAsRead(for topic: Topic, modelContext: ModelContext) {
        for message in topic.messages where !message.isRead {
            message.isRead = true
        }
        do {
            try modelContext.save()
        } catch {
            print("Failed to mark all messages as read: \(error)")
        }
    }

    func deleteMessage(_ message: Message, modelContext: ModelContext) {
        modelContext.delete(message)
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete message: \(error)")
        }
    }

    // MARK: - Private

    private func requestNotificationPermission() async {
        _ = await notificationService.requestPermission()
    }
}

// MARK: - Random Topic Name Generator

extension AppState {
    static func randomTopicName() -> String {
        let adjectives = ["swift", "happy", "lazy", "brave", "calm", "clever", "eager", "fancy", "gentle", "jolly"]
        let nouns = ["fox", "owl", "bear", "wolf", "hawk", "deer", "lion", "tiger", "eagle", "raven"]
        let adj = adjectives.randomElement()!
        let noun = nouns.randomElement()!
        let num = Int.random(in: 100...999)
        return "\(adj)-\(noun)-\(num)"
    }
}
