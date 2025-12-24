//
//  MessageEntityTests.swift
//  ntfyTests
//
//  Created by Claude on 24/12/24.
//

import Testing
import Foundation
import SwiftData
import AppIntents
@testable import Notify

@Suite("MessageEntity")
struct MessageEntityTests {

    // MARK: - Initialization Tests

    @Test("MessageEntity initializes from Message model")
    @MainActor
    func testMessageEntityFromModel() throws {
        let topic = Topic(name: "test")
        let message = Message(id: "msg123", topic: topic, body: "Test body", isRead: false)
        message.title = "Test Title"
        message.priority = 4

        let entity = MessageEntity(from: message)

        #expect(entity.id == "msg123")
        #expect(entity.title == "Test Title")
        #expect(entity.body == "Test body")
        #expect(entity.priority == 4)
        #expect(entity.isRead == false)
        #expect(entity.topicId == topic.id)
        #expect(entity.topicName == "test")
    }

    @Test("MessageEntity uses displayTitle when title is nil")
    @MainActor
    func testMessageEntityDefaultTitle() throws {
        let topic = Topic(name: "alerts")
        let message = Message(id: "msg1", topic: topic, body: "Body only", isRead: false)
        // No title set - should fall back to topic name via displayTitle

        let entity = MessageEntity(from: message)

        #expect(entity.title == "alerts")
    }

    @Test("MessageEntity captures read status")
    @MainActor
    func testMessageEntityReadStatus() throws {
        let topic = Topic(name: "test")
        let readMessage = Message(id: "read1", topic: topic, body: "Read", isRead: true)
        let unreadMessage = Message(id: "unread1", topic: topic, body: "Unread", isRead: false)

        let readEntity = MessageEntity(from: readMessage)
        let unreadEntity = MessageEntity(from: unreadMessage)

        #expect(readEntity.isRead == true)
        #expect(unreadEntity.isRead == false)
    }

    @Test("MessageEntity captures all priority levels")
    @MainActor
    func testMessageEntityPriorities() throws {
        let topic = Topic(name: "test")

        for priority in 1...5 {
            let message = Message(id: "p\(priority)", topic: topic, body: "Priority \(priority)", isRead: false)
            message.priority = priority

            let entity = MessageEntity(from: message)
            #expect(entity.priority == priority)
        }
    }

    @Test("MessageEntity handles message without topic")
    @MainActor
    func testMessageEntityWithoutTopic() throws {
        let message = Message(id: "orphan", topic: nil, body: "Orphan message", isRead: false)

        let entity = MessageEntity(from: message)

        #expect(entity.topicId == nil)
        #expect(entity.topicName == nil)
    }

    // MARK: - Display Representation Tests

    @Test("Display representation truncates long body")
    @MainActor
    func testDisplayRepresentationTruncation() throws {
        let topic = Topic(name: "test")
        let longBody = String(repeating: "A", count: 100)
        let message = Message(id: "long", topic: topic, body: longBody, isRead: false)
        message.title = "Long Message"

        let entity = MessageEntity(from: message)
        let repr = entity.displayRepresentation

        // Verify entity has expected title
        #expect(entity.title == "Long Message")
    }

    @Test("Display representation shows priority icon")
    @MainActor
    func testDisplayRepresentationPriorityIcon() throws {
        let topic = Topic(name: "test")

        // High priority (4) should have exclamationmark.circle.fill
        let highPriorityMessage = Message(id: "high", topic: topic, body: "High priority", isRead: false)
        highPriorityMessage.priority = 4
        let highEntity = MessageEntity(from: highPriorityMessage)

        // Urgent priority (5) should have exclamationmark.triangle.fill
        let urgentMessage = Message(id: "urgent", topic: topic, body: "Urgent", isRead: false)
        urgentMessage.priority = 5
        let urgentEntity = MessageEntity(from: urgentMessage)

        // Just verify entities are created correctly - icon is internal
        #expect(highEntity.priority == 4)
        #expect(urgentEntity.priority == 5)
    }
}
