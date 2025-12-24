//
//  IntentDependencies.swift
//  ntfy
//
//  Created by Claude on 24/12/24.
//

import AppIntents
import SwiftData

/// Provides ModelContext access for App Intents
@MainActor
final class IntentModelContextProvider: @unchecked Sendable {
    static let shared = IntentModelContextProvider()

    private var _modelContainer: ModelContainer?

    var modelContainer: ModelContainer {
        get {
            if let container = _modelContainer {
                return container
            }
            // Create container if not set (for extension use)
            let schema = Schema([Topic.self, Message.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            let container = try! ModelContainer(for: schema, configurations: [config])
            _modelContainer = container
            return container
        }
        set {
            _modelContainer = newValue
        }
    }

    var modelContext: ModelContext {
        modelContainer.mainContext
    }

    private init() {}
}

// MARK: - Custom Intent Errors

enum IntentError: Swift.Error, CustomLocalizedStringResourceConvertible {
    case topicNotFound
    case messageNotFound
    case cannotDeleteManagedTopic
    case invalidParameter(String)

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .topicNotFound:
            return "Topic not found"
        case .messageNotFound:
            return "Message not found"
        case .cannotDeleteManagedTopic:
            return "Cannot delete a topic managed by your organization"
        case .invalidParameter(let param):
            return LocalizedStringResource(stringLiteral: "Invalid parameter: \(param)")
        }
    }
}
