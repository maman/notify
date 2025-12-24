//
//  UnsubscribeFromTopicIntent.swift
//  ntfy
//
//  Created by Claude on 24/12/24.
//

import AppIntents
import SwiftData

/// Intent to unsubscribe from ntfy topics
struct UnsubscribeFromTopicIntent: AppIntent {
    static var title: LocalizedStringResource = "Unsubscribe from Topic"
    static var description = IntentDescription("Unsubscribe from an ntfy topic")

    @Parameter(title: "Topics")
    var topics: [TopicEntity]

    @Dependency
    var contextProvider: IntentModelContextProvider

    static var parameterSummary: some ParameterSummary {
        Summary("Unsubscribe from \(\.$topics)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = contextProvider.modelContext
        var unsubscribedCount = 0
        var skippedMDM = 0

        for entity in topics {
            let topicId = entity.id
            let descriptor = FetchDescriptor<Topic>(predicate: #Predicate { $0.id == topicId })
            guard let topic = try context.fetch(descriptor).first else { continue }

            // Skip MDM-managed topics
            if topic.isManagedByMDM {
                skippedMDM += 1
                continue
            }

            context.delete(topic)
            unsubscribedCount += 1
        }

        try context.save()

        if skippedMDM > 0 {
            return .result(
                dialog: IntentDialog(stringLiteral: "Unsubscribed from \(unsubscribedCount) topic\(unsubscribedCount == 1 ? "" : "s"). \(skippedMDM) managed topic\(skippedMDM == 1 ? " was" : "s were") skipped.")
            )
        }

        return .result(
            dialog: IntentDialog(stringLiteral: "Unsubscribed from \(unsubscribedCount) topic\(unsubscribedCount == 1 ? "" : "s")")
        )
    }
}
