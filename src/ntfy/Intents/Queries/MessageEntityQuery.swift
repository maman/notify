//
//  MessageEntityQuery.swift
//  ntfy
//
//  Created by Claude on 24/12/24.
//

import AppIntents
import SwiftData

/// EntityQuery for finding and searching Message entities
struct MessageEntityQuery: EntityQuery {
    @Dependency
    var contextProvider: IntentModelContextProvider

    @MainActor
    func entities(for identifiers: [String]) async throws -> [MessageEntity] {
        let context = contextProvider.modelContext
        let descriptor = FetchDescriptor<Message>()
        let messages = try context.fetch(descriptor)
        return messages
            .filter { identifiers.contains($0.id) }
            .map { MessageEntity(from: $0) }
    }

    @MainActor
    func suggestedEntities() async throws -> [MessageEntity] {
        let context = contextProvider.modelContext
        var descriptor = FetchDescriptor<Message>(
            predicate: #Predicate { !$0.isRead },
            sortBy: [SortDescriptor(\.receivedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 20
        let messages = try context.fetch(descriptor)
        return messages.map { MessageEntity(from: $0) }
    }
}

// MARK: - String Search

extension MessageEntityQuery: EntityStringQuery {
    @MainActor
    func entities(matching string: String) async throws -> [MessageEntity] {
        let context = contextProvider.modelContext
        var descriptor = FetchDescriptor<Message>(
            sortBy: [SortDescriptor(\.receivedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 50

        let messages = try context.fetch(descriptor)

        let query = string.lowercased()
        return messages
            .filter {
                $0.body.lowercased().contains(query) ||
                ($0.title?.lowercased().contains(query) ?? false) ||
                ($0.topic?.name.lowercased().contains(query) ?? false)
            }
            .prefix(20)
            .map { MessageEntity(from: $0) }
    }
}
