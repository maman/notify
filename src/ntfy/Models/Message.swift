//
//  Message.swift
//  ntfy
//
//  Created by Achmad Mahardi on 19/12/25.
//

import Foundation
import SwiftData

@Model
final class Message {
    @Attribute(.unique) var id: String
    var topic: Topic?
    var title: String?
    var body: String
    var priority: Int
    var tags: [String]?
    var click: String?
    var actionsData: Data?
    var isRead: Bool
    var receivedAt: Date

    init(
        id: String,
        topic: Topic? = nil,
        title: String? = nil,
        body: String,
        priority: Int = 3,
        tags: [String]? = nil,
        click: String? = nil,
        actions: [MessageAction]? = nil,
        isRead: Bool = false,
        receivedAt: Date = Date()
    ) {
        self.id = id
        self.topic = topic
        self.title = title
        self.body = body
        self.priority = priority
        self.tags = tags
        self.click = click
        self.actionsData = try? JSONEncoder().encode(actions)
        self.isRead = isRead
        self.receivedAt = receivedAt
    }

    var actions: [MessageAction]? {
        get {
            guard let data = actionsData else { return nil }
            return try? JSONDecoder().decode([MessageAction].self, from: data)
        }
        set {
            actionsData = try? JSONEncoder().encode(newValue)
        }
    }

    var displayTitle: String {
        title ?? topic?.effectiveDisplayName ?? String(localized: "Notification")
    }

    var priorityIcon: String {
        switch priority {
        case 5: return "exclamationmark.triangle.fill"
        case 4: return "exclamationmark.circle.fill"
        case 2: return "arrow.down.circle"
        case 1: return "minus.circle"
        default: return "bell"
        }
    }
}

nonisolated struct MessageAction: Codable, Identifiable, Sendable {
    var id: String { "\(action)-\(label)" }
    let action: String      // "view", "http", "broadcast"
    let label: String
    let url: String?
    let method: String?
    let headers: [String: String]?
    let body: String?
    let clear: Bool?

    init(action: String, label: String, url: String? = nil, method: String? = nil, headers: [String: String]? = nil, body: String? = nil, clear: Bool? = nil) {
        self.action = action
        self.label = label
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
        self.clear = clear
    }
}

// MARK: - NtfyMessage Conversion

extension Message {
    /// Create a Message from an NtfyMessage
    @MainActor
    static func from(_ ntfyMessage: NtfyMessage, topic: Topic) -> Message {
        Message(
            id: ntfyMessage.id,
            topic: topic,
            title: ntfyMessage.title,
            body: ntfyMessage.message ?? "",
            priority: ntfyMessage.priority ?? 3,
            tags: ntfyMessage.tags,
            click: ntfyMessage.click,
            actions: ntfyMessage.actions?.map { $0.toMessageAction() },
            isRead: false,
            receivedAt: ntfyMessage.date
        )
    }
}
