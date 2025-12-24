//
//  MarkMessageAsReadIntent.swift
//  ntfy
//
//  Created by Claude on 24/12/24.
//

import AppIntents
import SwiftData

/// Intent to mark a single message as read
struct MarkMessageAsReadIntent: AppIntent {
    static var title: LocalizedStringResource = "Mark Message as Read"
    static var description = IntentDescription("Mark a notification message as read")

    @Parameter(title: "Message")
    var message: MessageEntity

    @Dependency
    var contextProvider: IntentModelContextProvider

    static var parameterSummary: some ParameterSummary {
        Summary("Mark \(\.$message) as read")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = contextProvider.modelContext
        let messageId = message.id
        let descriptor = FetchDescriptor<Message>(predicate: #Predicate { $0.id == messageId })

        guard let dbMessage = try context.fetch(descriptor).first else {
            throw IntentError.messageNotFound
        }

        if dbMessage.isRead {
            return .result(dialog: IntentDialog(stringLiteral: "Message was already read"))
        }

        dbMessage.isRead = true
        try context.save()

        return .result(dialog: IntentDialog(stringLiteral: "Message marked as read"))
    }
}
