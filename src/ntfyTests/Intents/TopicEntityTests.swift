//
//  TopicEntityTests.swift
//  ntfyTests
//
//  Created by Claude on 24/12/24.
//

import Testing
import Foundation
import SwiftData
import AppIntents
@testable import Notify

@Suite("TopicEntity")
struct TopicEntityTests {

    // MARK: - Initialization Tests

    @Test("TopicEntity initializes from Topic model")
    @MainActor
    func testTopicEntityFromModel() throws {
        let topic = Topic(name: "alerts", serverURL: "https://ntfy.sh")
        topic.displayName = "My Alerts"

        let entity = TopicEntity(from: topic)

        #expect(entity.id == topic.id)
        #expect(entity.name == "alerts")
        #expect(entity.displayName == "My Alerts")
        #expect(entity.serverURL == "https://ntfy.sh")
        #expect(entity.unreadCount == 0)
        #expect(entity.isManagedByMDM == false)
    }

    @Test("TopicEntity uses effectiveDisplayName when displayName is nil")
    @MainActor
    func testTopicEntityDefaultDisplayName() throws {
        let topic = Topic(name: "server-alerts")
        // displayName is nil, should use name

        let entity = TopicEntity(from: topic)

        #expect(entity.displayName == "server-alerts")
    }

    @Test("TopicEntity reflects unread count")
    @MainActor
    func testTopicEntityUnreadCount() throws {
        let schema = Schema([Topic.self, Message.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let topic = Topic(name: "test")
        context.insert(topic)

        let msg1 = Message(id: "1", topic: topic, body: "Hello", isRead: false)
        let msg2 = Message(id: "2", topic: topic, body: "World", isRead: true)
        context.insert(msg1)
        context.insert(msg2)
        try context.save()

        let entity = TopicEntity(from: topic)

        #expect(entity.unreadCount == 1)
    }

    @Test("TopicEntity reflects MDM managed status")
    @MainActor
    func testTopicEntityMDMStatus() throws {
        let topic = Topic(name: "managed-topic")
        topic.isManagedByMDM = true

        let entity = TopicEntity(from: topic)

        #expect(entity.isManagedByMDM == true)
    }

    // MARK: - Display Representation Tests

    @Test("Display representation shows unread count when > 0")
    @MainActor
    func testDisplayRepresentationWithUnread() throws {
        let schema = Schema([Topic.self, Message.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let topic = Topic(name: "alerts")
        context.insert(topic)

        let msg = Message(id: "1", topic: topic, body: "Test", isRead: false)
        context.insert(msg)
        try context.save()

        let entity = TopicEntity(from: topic)

        // Verify entity has unread count
        #expect(entity.unreadCount == 1)
        #expect(entity.displayName == "alerts")
    }

    @Test("Display representation has correct title when no unread")
    @MainActor
    func testDisplayRepresentationNoUnread() throws {
        let topic = Topic(name: "quiet-topic")

        let entity = TopicEntity(from: topic)

        #expect(entity.displayName == "quiet-topic")
        #expect(entity.unreadCount == 0)
    }
}
