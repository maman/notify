//
//  MarkAllMessagesAsReadIntent.swift
//  ntfy
//
//  Created by Claude on 24/12/24.
//

import AppIntents
import SwiftData

/// Intent to mark all messages in a topic as read
struct MarkAllMessagesAsReadIntent: AppIntent {
    static var title: LocalizedStringResource = "Mark All Messages as Read"
    static var description = IntentDescription("Mark all messages in a topic as read")

    @Parameter(title: "Topic")
    var topic: TopicEntity

    @Dependency
    var contextProvider: IntentModelContextProvider

    static var parameterSummary: some ParameterSummary {
        Summary("Mark all messages in \(\.$topic) as read")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Int> & ProvidesDialog {
        let context = contextProvider.modelContext
        let topicId = topic.id
        let descriptor = FetchDescriptor<Topic>(predicate: #Predicate { $0.id == topicId })

        guard let dbTopic = try context.fetch(descriptor).first else {
            throw IntentError.topicNotFound
        }

        let unreadMessages = dbTopic.messages.filter { !$0.isRead }
        let count = unreadMessages.count

        if count == 0 {
            return .result(
                value: 0,
                dialog: IntentDialog(stringLiteral: "No unread messages in \(topic.displayName)")
            )
        }

        for message in unreadMessages {
            message.isRead = true
        }
        try context.save()

        return .result(
            value: count,
            dialog: IntentDialog(stringLiteral: "Marked \(count) message\(count == 1 ? "" : "s") as read in \(topic.displayName)")
        )
    }
}
