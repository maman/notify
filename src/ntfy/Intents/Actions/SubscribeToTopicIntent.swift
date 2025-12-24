//
//  SubscribeToTopicIntent.swift
//  ntfy
//
//  Created by Claude on 24/12/24.
//

import AppIntents
import SwiftData

/// Intent to subscribe to a new ntfy topic
struct SubscribeToTopicIntent: AppIntent {
    static var title: LocalizedStringResource = "Subscribe to Topic"
    static var description = IntentDescription("Subscribe to a new ntfy topic to receive notifications")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Topic Name")
    var topicName: String

    @Parameter(title: "Server URL", default: "https://ntfy.sh")
    var serverURL: String

    @Dependency
    var contextProvider: IntentModelContextProvider

    static var parameterSummary: some ParameterSummary {
        Summary("Subscribe to \(\.$topicName) on \(\.$serverURL)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<TopicEntity> & ProvidesDialog {
        let context = contextProvider.modelContext

        // Validate topic name
        let trimmedName = topicName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw IntentError.invalidParameter("Topic name cannot be empty")
        }

        // Check if topic already exists
        let existingDescriptor = FetchDescriptor<Topic>(
            predicate: #Predicate { topic in
                topic.name == trimmedName && topic.serverURL == serverURL
            }
        )
        if let existing = try context.fetch(existingDescriptor).first {
            let entity = TopicEntity(from: existing)
            return .result(
                value: entity,
                dialog: IntentDialog(stringLiteral: "You're already subscribed to \(trimmedName)")
            )
        }

        // Create new topic
        let topic = Topic(name: trimmedName, serverURL: serverURL)
        context.insert(topic)
        try context.save()

        let entity = TopicEntity(from: topic)

        return .result(
            value: entity,
            dialog: IntentDialog(stringLiteral: "Subscribed to \(trimmedName)")
        )
    }
}
