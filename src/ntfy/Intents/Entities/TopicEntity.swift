//
//  TopicEntity.swift
//  ntfy
//
//  Created by Claude on 24/12/24.
//

import AppIntents
import SwiftData

/// AppEntity wrapper for Topic model, exposing it to App Intents
struct TopicEntity: AppEntity, Sendable {
    var id: UUID

    @Property(title: "Name")
    var name: String

    @Property(title: "Display Name")
    var displayName: String

    @Property(title: "Server URL")
    var serverURL: String

    @Property(title: "Unread Count")
    var unreadCount: Int

    @Property(title: "Is Managed")
    var isManagedByMDM: Bool

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(
            name: LocalizedStringResource("Topic"),
            numericFormat: LocalizedStringResource("\(placeholder: .int) topics")
        )
    }

    static var defaultQuery = TopicEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(displayName)",
            subtitle: unreadCount > 0 ? LocalizedStringResource("\(unreadCount) unread") : nil,
            image: .init(systemName: unreadCount > 0 ? "bell.badge.fill" : "bell.fill")
        )
    }

    init(id: UUID, name: String, displayName: String, serverURL: String, unreadCount: Int, isManagedByMDM: Bool) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.serverURL = serverURL
        self.unreadCount = unreadCount
        self.isManagedByMDM = isManagedByMDM
    }

    @MainActor
    init(from topic: Topic) {
        self.id = topic.id
        self.name = topic.name
        self.displayName = topic.effectiveDisplayName
        self.serverURL = topic.serverURL
        self.unreadCount = topic.unreadCount
        self.isManagedByMDM = topic.isManagedByMDM
    }
}
