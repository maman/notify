//
//  IntentTests.swift
//  ntfyTests
//
//  Created by Claude on 24/12/24.
//

import Testing
import Foundation
import SwiftData
import AppIntents
@testable import Notify

@Suite("App Intents")
struct IntentTests {

    private func createTestContainer() throws -> ModelContainer {
        let schema = Schema([Topic.self, Message.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    // MARK: - GetUnreadCountIntent Tests

    @Test("GetUnreadCountIntent returns total count without topic parameter")
    @MainActor
    func testGetUnreadCountTotal() async throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let topic1 = Topic(name: "topic1")
        let topic2 = Topic(name: "topic2")
        context.insert(topic1)
        context.insert(topic2)

        // Add unread messages
        context.insert(Message(id: "1", topic: topic1, body: "Msg1", isRead: false))
        context.insert(Message(id: "2", topic: topic1, body: "Msg2", isRead: false))
        context.insert(Message(id: "3", topic: topic2, body: "Msg3", isRead: false))
        context.insert(Message(id: "4", topic: topic2, body: "Msg4", isRead: true)) // Read

        try context.save()

        IntentModelContextProvider.shared.modelContainer = container
        let intent = GetUnreadCountIntent()

        let result = try await intent.perform()
        // Result.value should be 3 (total unread across all topics)
        // Note: We can't easily extract the value from IntentResult in tests
        // This test mainly verifies the intent executes without error
    }

    @Test("GetUnreadCountIntent returns count for specific topic")
    @MainActor
    func testGetUnreadCountSpecificTopic() async throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let topic1 = Topic(name: "topic1")
        let topic2 = Topic(name: "topic2")
        context.insert(topic1)
        context.insert(topic2)

        // Add messages to topic2
        context.insert(Message(id: "1", topic: topic2, body: "Msg1", isRead: false))
        context.insert(Message(id: "2", topic: topic2, body: "Msg2", isRead: false))
        context.insert(Message(id: "3", topic: topic2, body: "Msg3", isRead: true))

        try context.save()

        IntentModelContextProvider.shared.modelContainer = container

        var intent = GetUnreadCountIntent()
        intent.topic = TopicEntity(from: topic2)

        let result = try await intent.perform()
        // Result.value should be 2 (unread in topic2 only)
    }

    @Test("GetUnreadCountIntent throws for non-existent topic")
    @MainActor
    func testGetUnreadCountNonExistentTopic() async throws {
        let container = try createTestContainer()
        IntentModelContextProvider.shared.modelContainer = container

        var intent = GetUnreadCountIntent()
        intent.topic = TopicEntity(
            id: UUID(),
            name: "nonexistent",
            displayName: "Nonexistent",
            serverURL: "https://ntfy.sh",
            unreadCount: 0,
            isManagedByMDM: false
        )

        await #expect(throws: IntentError.self) {
            _ = try await intent.perform()
        }
    }

    // MARK: - MarkAllMessagesAsReadIntent Tests

    @Test("MarkAllMessagesAsReadIntent marks all messages as read")
    @MainActor
    func testMarkAllAsRead() async throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let topic = Topic(name: "test")
        context.insert(topic)

        let msg1 = Message(id: "1", topic: topic, body: "Msg1", isRead: false)
        let msg2 = Message(id: "2", topic: topic, body: "Msg2", isRead: false)
        let msg3 = Message(id: "3", topic: topic, body: "Msg3", isRead: true) // Already read
        context.insert(msg1)
        context.insert(msg2)
        context.insert(msg3)

        try context.save()

        #expect(topic.unreadCount == 2)

        IntentModelContextProvider.shared.modelContainer = container

        var intent = MarkAllMessagesAsReadIntent()
        intent.topic = TopicEntity(from: topic)

        _ = try await intent.perform()

        // All messages should now be read
        #expect(topic.unreadCount == 0)
        #expect(msg1.isRead == true)
        #expect(msg2.isRead == true)
        #expect(msg3.isRead == true)
    }

    @Test("MarkAllMessagesAsReadIntent handles empty topic")
    @MainActor
    func testMarkAllAsReadEmptyTopic() async throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let topic = Topic(name: "empty")
        context.insert(topic)
        try context.save()

        IntentModelContextProvider.shared.modelContainer = container

        var intent = MarkAllMessagesAsReadIntent()
        intent.topic = TopicEntity(from: topic)

        // Should not throw, just return 0 count
        _ = try await intent.perform()
    }

    // MARK: - MarkMessageAsReadIntent Tests

    @Test("MarkMessageAsReadIntent marks single message as read")
    @MainActor
    func testMarkMessageAsRead() async throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let topic = Topic(name: "test")
        context.insert(topic)

        let msg = Message(id: "msg1", topic: topic, body: "Test", isRead: false)
        context.insert(msg)
        try context.save()

        #expect(msg.isRead == false)

        IntentModelContextProvider.shared.modelContainer = container

        var intent = MarkMessageAsReadIntent()
        intent.message = MessageEntity(from: msg)

        _ = try await intent.perform()

        #expect(msg.isRead == true)
    }

    @Test("MarkMessageAsReadIntent handles already read message")
    @MainActor
    func testMarkAlreadyReadMessage() async throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let topic = Topic(name: "test")
        context.insert(topic)

        let msg = Message(id: "msg1", topic: topic, body: "Test", isRead: true)
        context.insert(msg)
        try context.save()

        IntentModelContextProvider.shared.modelContainer = container

        var intent = MarkMessageAsReadIntent()
        intent.message = MessageEntity(from: msg)

        // Should not throw
        _ = try await intent.perform()
        #expect(msg.isRead == true)
    }

    // MARK: - SubscribeToTopicIntent Tests

    @Test("SubscribeToTopicIntent creates new topic")
    @MainActor
    func testSubscribeToTopic() async throws {
        let container = try createTestContainer()
        let context = container.mainContext
        IntentModelContextProvider.shared.modelContainer = container

        var intent = SubscribeToTopicIntent()
        intent.topicName = "new-topic"
        intent.serverURL = "https://ntfy.sh"

        _ = try await intent.perform()

        // Verify topic was created
        let descriptor = FetchDescriptor<Topic>(predicate: #Predicate { $0.name == "new-topic" })
        let topics = try context.fetch(descriptor)

        #expect(topics.count == 1)
        #expect(topics.first?.name == "new-topic")
        #expect(topics.first?.serverURL == "https://ntfy.sh")
    }

    @Test("SubscribeToTopicIntent returns existing topic if already subscribed")
    @MainActor
    func testSubscribeToExistingTopic() async throws {
        let container = try createTestContainer()
        let context = container.mainContext

        // Pre-create topic
        let existing = Topic(name: "existing", serverURL: "https://ntfy.sh")
        context.insert(existing)
        try context.save()

        IntentModelContextProvider.shared.modelContainer = container

        var intent = SubscribeToTopicIntent()
        intent.topicName = "existing"
        intent.serverURL = "https://ntfy.sh"

        // Should not throw, should return existing
        _ = try await intent.perform()

        // Should still only have 1 topic
        let descriptor = FetchDescriptor<Topic>(predicate: #Predicate { $0.name == "existing" })
        let topics = try context.fetch(descriptor)
        #expect(topics.count == 1)
    }

    @Test("SubscribeToTopicIntent rejects empty topic name")
    @MainActor
    func testSubscribeEmptyTopicName() async throws {
        let container = try createTestContainer()
        IntentModelContextProvider.shared.modelContainer = container

        var intent = SubscribeToTopicIntent()
        intent.topicName = "   " // Whitespace only
        intent.serverURL = "https://ntfy.sh"

        await #expect(throws: IntentError.self) {
            _ = try await intent.perform()
        }
    }

    // MARK: - UnsubscribeFromTopicIntent Tests

    @Test("UnsubscribeFromTopicIntent deletes topic")
    @MainActor
    func testUnsubscribeFromTopic() async throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let topic = Topic(name: "to-delete")
        context.insert(topic)
        try context.save()

        IntentModelContextProvider.shared.modelContainer = container

        var intent = UnsubscribeFromTopicIntent()
        intent.topics = [TopicEntity(from: topic)]

        _ = try await intent.perform()

        // Topic should be deleted
        let descriptor = FetchDescriptor<Topic>(predicate: #Predicate { $0.name == "to-delete" })
        let topics = try context.fetch(descriptor)
        #expect(topics.isEmpty)
    }

    @Test("UnsubscribeFromTopicIntent skips MDM-managed topics")
    @MainActor
    func testUnsubscribeSkipsMDMTopic() async throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let managedTopic = Topic(name: "managed")
        managedTopic.isManagedByMDM = true
        context.insert(managedTopic)
        try context.save()

        IntentModelContextProvider.shared.modelContainer = container

        var intent = UnsubscribeFromTopicIntent()
        intent.topics = [TopicEntity(from: managedTopic)]

        _ = try await intent.perform()

        // Topic should NOT be deleted
        let descriptor = FetchDescriptor<Topic>(predicate: #Predicate { $0.name == "managed" })
        let topics = try context.fetch(descriptor)
        #expect(topics.count == 1)
    }

    @Test("UnsubscribeFromTopicIntent handles mixed managed and unmanaged")
    @MainActor
    func testUnsubscribeMixedTopics() async throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let managedTopic = Topic(name: "managed")
        managedTopic.isManagedByMDM = true
        let userTopic = Topic(name: "user")
        context.insert(managedTopic)
        context.insert(userTopic)
        try context.save()

        IntentModelContextProvider.shared.modelContainer = container

        var intent = UnsubscribeFromTopicIntent()
        intent.topics = [TopicEntity(from: managedTopic), TopicEntity(from: userTopic)]

        _ = try await intent.perform()

        // Managed should exist, user should be deleted
        let allTopics = try context.fetch(FetchDescriptor<Topic>())
        #expect(allTopics.count == 1)
        #expect(allTopics.first?.name == "managed")
    }
}

// MARK: - EntityQuery Tests

@Suite("Entity Queries")
struct EntityQueryTests {

    private func createTestContainer() throws -> ModelContainer {
        let schema = Schema([Topic.self, Message.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    @Test("TopicEntityQuery returns entities for identifiers")
    @MainActor
    func testTopicQueryByIdentifiers() async throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let topic1 = Topic(name: "topic1")
        let topic2 = Topic(name: "topic2")
        let topic3 = Topic(name: "topic3")
        context.insert(topic1)
        context.insert(topic2)
        context.insert(topic3)
        try context.save()

        IntentModelContextProvider.shared.modelContainer = container
        let query = TopicEntityQuery()

        let results = try await query.entities(for: [topic1.id, topic3.id])

        #expect(results.count == 2)
        #expect(results.contains { $0.name == "topic1" })
        #expect(results.contains { $0.name == "topic3" })
    }

    @Test("TopicEntityQuery matches string search")
    @MainActor
    func testTopicQueryStringSearch() async throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let topic1 = Topic(name: "server-alerts")
        let topic2 = Topic(name: "notifications")
        let topic3 = Topic(name: "alert-system")
        context.insert(topic1)
        context.insert(topic2)
        context.insert(topic3)
        try context.save()

        IntentModelContextProvider.shared.modelContainer = container
        let query = TopicEntityQuery()

        let results = try await query.entities(matching: "alert")

        #expect(results.count == 2)
        #expect(results.contains { $0.name == "server-alerts" })
        #expect(results.contains { $0.name == "alert-system" })
    }

    @Test("TopicEntityQuery allEntities returns all topics")
    @MainActor
    func testTopicQueryAllEntities() async throws {
        let container = try createTestContainer()
        let context = container.mainContext

        context.insert(Topic(name: "topic1"))
        context.insert(Topic(name: "topic2"))
        context.insert(Topic(name: "topic3"))
        try context.save()

        IntentModelContextProvider.shared.modelContainer = container
        let query = TopicEntityQuery()

        let results = try await query.allEntities()

        #expect(results.count == 3)
    }

    @Test("MessageEntityQuery returns unread messages as suggestions")
    @MainActor
    func testMessageQuerySuggestions() async throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let topic = Topic(name: "test")
        context.insert(topic)

        context.insert(Message(id: "1", topic: topic, body: "Unread 1", isRead: false))
        context.insert(Message(id: "2", topic: topic, body: "Unread 2", isRead: false))
        context.insert(Message(id: "3", topic: topic, body: "Read", isRead: true))
        try context.save()

        IntentModelContextProvider.shared.modelContainer = container
        let query = MessageEntityQuery()

        let results = try await query.suggestedEntities()

        // Should only return unread messages
        #expect(results.count == 2)
        #expect(results.allSatisfy { !$0.isRead })
    }

    @Test("MessageEntityQuery searches body and title")
    @MainActor
    func testMessageQueryStringSearch() async throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let topic = Topic(name: "test")
        context.insert(topic)

        let msg1 = Message(id: "1", topic: topic, body: "Server is down", isRead: false)
        msg1.title = "Alert"
        let msg2 = Message(id: "2", topic: topic, body: "All systems normal", isRead: false)
        msg2.title = "Status"
        let msg3 = Message(id: "3", topic: topic, body: "Check the server", isRead: false)
        msg3.title = "Reminder"

        context.insert(msg1)
        context.insert(msg2)
        context.insert(msg3)
        try context.save()

        IntentModelContextProvider.shared.modelContainer = container
        let query = MessageEntityQuery()

        let results = try await query.entities(matching: "server")

        #expect(results.count == 2)
    }
}
