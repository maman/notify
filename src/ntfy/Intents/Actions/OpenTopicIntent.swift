//
//  OpenTopicIntent.swift
//  ntfy
//
//  Created by Claude on 24/12/24.
//

import AppIntents
import SwiftData

/// Intent to open a topic in the app
struct OpenTopicIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Topic"
    static var description = IntentDescription("Open a topic in the Notify app")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Topic")
    var topic: TopicEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Open \(\.$topic)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Post notification to open the topic window and select topic
        NotificationCenter.default.post(
            name: .openTopic,
            object: nil,
            userInfo: ["topicId": topic.id.uuidString]
        )

        return .result(
            dialog: IntentDialog(stringLiteral: "Opening \(topic.displayName)")
        )
    }
}
