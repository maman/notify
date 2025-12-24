//
//  TopicEntityQuery.swift
//  ntfy
//
//  Created by Claude on 24/12/24.
//

import AppIntents
import SwiftData

/// EntityQuery for finding and searching Topic entities
struct TopicEntityQuery: EntityQuery {
    @Dependency
    var contextProvider: IntentModelContextProvider

    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [TopicEntity] {
        let context = contextProvider.modelContext
        let descriptor = FetchDescriptor<Topic>()
        let topics = try context.fetch(descriptor)
        return topics
            .filter { identifiers.contains($0.id) }
            .map { TopicEntity(from: $0) }
    }

    @MainActor
    func suggestedEntities() async throws -> [TopicEntity] {
        let context = contextProvider.modelContext
        let descriptor = FetchDescriptor<Topic>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        let topics = try context.fetch(descriptor)
        return topics.map { TopicEntity(from: $0) }
    }
}

// MARK: - String Search

extension TopicEntityQuery: EntityStringQuery {
    @MainActor
    func entities(matching string: String) async throws -> [TopicEntity] {
        let context = contextProvider.modelContext
        let descriptor = FetchDescriptor<Topic>()
        let topics = try context.fetch(descriptor)

        let query = string.lowercased()
        return topics
            .filter {
                $0.name.lowercased().contains(query) ||
                $0.effectiveDisplayName.lowercased().contains(query)
            }
            .map { TopicEntity(from: $0) }
    }
}

// MARK: - Enumerable (for small lists)

extension TopicEntityQuery: EnumerableEntityQuery {
    @MainActor
    func allEntities() async throws -> [TopicEntity] {
        try await suggestedEntities()
    }
}
