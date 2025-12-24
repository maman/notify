//
//  MessageEntity.swift
//  ntfy
//
//  Created by Claude on 24/12/24.
//

import AppIntents
import SwiftData

/// AppEntity wrapper for Message model, exposing it to App Intents
struct MessageEntity: AppEntity, Sendable {
    var id: String

    @Property(title: "Title")
    var title: String

    @Property(title: "Body")
    var body: String

    @Property(title: "Priority")
    var priority: Int

    @Property(title: "Is Read")
    var isRead: Bool

    @Property(title: "Received At")
    var receivedAt: Date

    var topicId: UUID?
    var topicName: String?

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(
            name: LocalizedStringResource("Message"),
            numericFormat: LocalizedStringResource("\(placeholder: .int) messages")
        )
    }

    static var defaultQuery = MessageEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        let subtitle = body.count > 50 ? "\(body.prefix(50))..." : body
        return DisplayRepresentation(
            title: "\(title)",
            subtitle: LocalizedStringResource(stringLiteral: subtitle),
            image: .init(systemName: priorityIcon)
        )
    }

    private var priorityIcon: String {
        switch priority {
        case 5: return "exclamationmark.triangle.fill"
        case 4: return "exclamationmark.circle.fill"
        case 2: return "arrow.down.circle"
        case 1: return "minus.circle"
        default: return "bell"
        }
    }

    init(id: String, title: String, body: String, priority: Int, isRead: Bool, receivedAt: Date, topicId: UUID?, topicName: String?) {
        self.id = id
        self.title = title
        self.body = body
        self.priority = priority
        self.isRead = isRead
        self.receivedAt = receivedAt
        self.topicId = topicId
        self.topicName = topicName
    }

    @MainActor
    init(from message: Message) {
        self.id = message.id
        self.title = message.displayTitle
        self.body = message.body
        self.priority = message.priority
        self.isRead = message.isRead
        self.receivedAt = message.receivedAt
        self.topicId = message.topic?.id
        self.topicName = message.topic?.effectiveDisplayName
    }
}
