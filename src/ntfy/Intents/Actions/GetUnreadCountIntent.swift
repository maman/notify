//
//  GetUnreadCountIntent.swift
//  ntfy
//
//  Created by Claude on 24/12/24.
//

import AppIntents
import SwiftData

/// Intent to get the unread message count for a topic or all topics
struct GetUnreadCountIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Unread Count"
    static var description = IntentDescription("Get the number of unread notifications")

    @Parameter(title: "Topic")
    var topic: TopicEntity?

    @Dependency
    var contextProvider: IntentModelContextProvider

    static var parameterSummary: some ParameterSummary {
        When(\.$topic, .hasAnyValue) {
            Summary("Get unread count for \(\.$topic)")
        } otherwise: {
            Summary("Get total unread count")
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Int> & ProvidesDialog {
        let context = contextProvider.modelContext

        if let topic = topic {
            // Get count for specific topic
            let topicId = topic.id
            let descriptor = FetchDescriptor<Topic>(predicate: #Predicate { $0.id == topicId })
            guard let dbTopic = try context.fetch(descriptor).first else {
                throw IntentError.topicNotFound
            }
            let count = dbTopic.unreadCount
            return .result(
                value: count,
                dialog: IntentDialog(stringLiteral: "\(count) unread message\(count == 1 ? "" : "s") in \(topic.displayName)")
            )
        } else {
            // Get total count across all topics
            let descriptor = FetchDescriptor<Topic>()
            let topics = try context.fetch(descriptor)
            let totalCount = topics.reduce(0) { $0 + $1.unreadCount }
            return .result(
                value: totalCount,
                dialog: IntentDialog(stringLiteral: "\(totalCount) total unread message\(totalCount == 1 ? "" : "s")")
            )
        }
    }
}
