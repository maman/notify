//
//  MessageTests.swift
//  ntfyTests
//
//  Created by Achmad Mahardi on 20/12/25.
//

import Testing
import Foundation
import SwiftData
@testable import Notify

@Suite("Message Model")
struct MessageTests {

    // MARK: - Actions JSON Encoding/Decoding Tests

    @Test("Actions encode and decode correctly")
    func actions_encodesAndDecodes_correctly() {
        let actions = [
            MessageAction(action: "view", label: "Open", url: "https://example.com"),
            MessageAction(action: "http", label: "Submit", url: "https://api.example.com", method: "POST", headers: ["X-Token": "abc"], body: "{}", clear: true)
        ]

        let message = Message(id: "test", body: "Test", actions: actions)

        let retrievedActions = message.actions
        #expect(retrievedActions?.count == 2)

        let firstAction = retrievedActions?[0]
        #expect(firstAction?.action == "view")
        #expect(firstAction?.label == "Open")
        #expect(firstAction?.url == "https://example.com")

        let secondAction = retrievedActions?[1]
        #expect(secondAction?.action == "http")
        #expect(secondAction?.label == "Submit")
        #expect(secondAction?.method == "POST")
        #expect(secondAction?.headers?["X-Token"] == "abc")
        #expect(secondAction?.body == "{}")
        #expect(secondAction?.clear == true)
    }

    @Test("Actions returns nil when no actions data")
    func actions_returnsNil_whenNoActionsData() {
        let message = Message(id: "test", body: "Test")
        #expect(message.actions == nil)
    }

    @Test("Actions can be set after initialization")
    func actions_canBeSetAfterInit() {
        var message = Message(id: "test", body: "Test")
        #expect(message.actions == nil)

        message.actions = [MessageAction(action: "view", label: "Click", url: "https://example.com")]

        #expect(message.actions?.count == 1)
        #expect(message.actions?[0].label == "Click")
    }

    @Test("Actions can be cleared by setting to nil")
    func actions_canBeCleared() {
        var message = Message(id: "test", body: "Test", actions: [MessageAction(action: "view", label: "Open")])
        #expect(message.actions != nil)

        message.actions = nil
        #expect(message.actions == nil)
    }

    // MARK: - displayTitle Tests

    @Test("displayTitle returns title when set")
    func displayTitle_returnsTitle_whenSet() {
        let message = Message(id: "test", title: "Alert Title", body: "Body text")
        #expect(message.displayTitle == "Alert Title")
    }

    @Test("displayTitle returns topic name when title is nil")
    @MainActor
    func displayTitle_returnsTopicName_whenTitleNil() throws {
        let schema = Schema([Topic.self, Message.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let topic = Topic(name: "server-alerts", displayName: "Server Alerts")
        context.insert(topic)

        let message = Message(id: "test", topic: topic, body: "Body text")
        context.insert(message)

        #expect(message.displayTitle == "Server Alerts")
    }

    @Test("displayTitle falls back to topic name when no displayName")
    @MainActor
    func displayTitle_fallsBackToTopicName() throws {
        let schema = Schema([Topic.self, Message.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let topic = Topic(name: "raw-topic-name")  // No displayName
        context.insert(topic)

        let message = Message(id: "test", topic: topic, body: "Body text")
        context.insert(message)

        #expect(message.displayTitle == "raw-topic-name")
    }

    @Test("displayTitle returns Notification when both title and topic are nil")
    func displayTitle_returnsNotification_whenBothNil() {
        let message = Message(id: "test", body: "Body text")
        // Without topic and title, should return localized "Notification"
        #expect(message.displayTitle == String(localized: "Notification"))
    }

    // MARK: - priorityIcon Tests

    @Test("priorityIcon returns correct icon for priority 5 (high)")
    func priorityIcon_priority5() {
        let message = Message(id: "test", body: "Test", priority: 5)
        #expect(message.priorityIcon == "exclamationmark.triangle.fill")
    }

    @Test("priorityIcon returns correct icon for priority 4 (medium-high)")
    func priorityIcon_priority4() {
        let message = Message(id: "test", body: "Test", priority: 4)
        #expect(message.priorityIcon == "exclamationmark.circle.fill")
    }

    @Test("priorityIcon returns correct icon for priority 3 (normal/default)")
    func priorityIcon_priority3() {
        let message = Message(id: "test", body: "Test", priority: 3)
        #expect(message.priorityIcon == "bell")
    }

    @Test("priorityIcon returns correct icon for priority 2 (low)")
    func priorityIcon_priority2() {
        let message = Message(id: "test", body: "Test", priority: 2)
        #expect(message.priorityIcon == "arrow.down.circle")
    }

    @Test("priorityIcon returns correct icon for priority 1 (very low)")
    func priorityIcon_priority1() {
        let message = Message(id: "test", body: "Test", priority: 1)
        #expect(message.priorityIcon == "minus.circle")
    }

    @Test("priorityIcon returns default bell for unknown priorities")
    func priorityIcon_unknownPriority() {
        let message = Message(id: "test", body: "Test", priority: 99)
        #expect(message.priorityIcon == "bell")
    }

    @Test("priorityIcon matches fixture mapping for all priorities")
    func priorityIcon_matchesAllPriorities() {
        for (priority, expectedIcon) in TestFixtures.priorityIconMapping {
            let message = Message(id: "test-\(priority)", body: "Test", priority: priority)
            #expect(message.priorityIcon == expectedIcon, "Priority \(priority) should have icon \(expectedIcon)")
        }
    }

    // MARK: - Message.from() Conversion Tests

    @Test("from() converts NtfyMessage correctly")
    @MainActor
    func from_convertsNtfyMessage_correctly() throws {
        let schema = Schema([Topic.self, Message.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let topic = Topic(name: "alerts")
        context.insert(topic)

        let data = TestFixtures.fullMessageJSON.data(using: .utf8)!
        let ntfyMessage = try JSONDecoder().decode(NtfyMessage.self, from: data)

        let message = Message.from(ntfyMessage, topic: topic)

        #expect(message.id == "msg123")
        #expect(message.body == "Server is down")
        #expect(message.title == "Critical Alert")
        #expect(message.priority == 5)
        #expect(message.tags == ["warning", "server"])
        #expect(message.click == "https://example.com/status")
        #expect(message.isRead == false)
        #expect(message.actions?.count == 2)
        #expect(message.receivedAt == ntfyMessage.date)
    }

    @Test("from() handles minimal NtfyMessage with optional fields")
    @MainActor
    func from_handlesOptionalFields() throws {
        let schema = Schema([Topic.self, Message.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let topic = Topic(name: "test")
        context.insert(topic)

        let data = TestFixtures.minimalMessageJSON.data(using: .utf8)!
        let ntfyMessage = try JSONDecoder().decode(NtfyMessage.self, from: data)

        let message = Message.from(ntfyMessage, topic: topic)

        #expect(message.id == "abc123")
        #expect(message.body == "")  // nil message becomes empty string
        #expect(message.title == nil)
        #expect(message.priority == 3)  // Default priority
        #expect(message.tags == nil)
        #expect(message.click == nil)
        #expect(message.actions == nil)
        #expect(message.isRead == false)
    }

    // MARK: - Initialization Tests

    @Test("Message initializes with default values")
    func init_setsDefaultValues() {
        let message = Message(id: "test123", body: "Test body")

        #expect(message.id == "test123")
        #expect(message.body == "Test body")
        #expect(message.topic == nil)
        #expect(message.title == nil)
        #expect(message.priority == 3)
        #expect(message.tags == nil)
        #expect(message.click == nil)
        #expect(message.actions == nil)
        #expect(message.isRead == false)
    }

    @Test("Message initializes with custom values")
    func init_setsCustomValues() {
        let customDate = Date(timeIntervalSince1970: 1000)
        let actions = [MessageAction(action: "view", label: "Open")]

        let message = Message(
            id: "custom123",
            title: "Custom Title",
            body: "Custom Body",
            priority: 5,
            tags: ["urgent", "server"],
            click: "https://example.com",
            actions: actions,
            isRead: true,
            receivedAt: customDate
        )

        #expect(message.id == "custom123")
        #expect(message.title == "Custom Title")
        #expect(message.body == "Custom Body")
        #expect(message.priority == 5)
        #expect(message.tags == ["urgent", "server"])
        #expect(message.click == "https://example.com")
        #expect(message.actions?.count == 1)
        #expect(message.isRead == true)
        #expect(message.receivedAt == customDate)
    }
}

// MARK: - MessageAction Tests

@Suite("MessageAction")
struct MessageActionTests {

    @Test("MessageAction id combines action and label")
    func id_combinesActionAndLabel() {
        let action = MessageAction(action: "view", label: "Open")
        #expect(action.id == "view-Open")
    }

    @Test("MessageAction id handles special characters")
    func id_handlesSpecialCharacters() {
        let action = MessageAction(action: "http", label: "Submit Form")
        #expect(action.id == "http-Submit Form")
    }

    @Test("MessageAction initializes with minimal values")
    func init_minimalValues() {
        let action = MessageAction(action: "broadcast", label: "Share")

        #expect(action.action == "broadcast")
        #expect(action.label == "Share")
        #expect(action.url == nil)
        #expect(action.method == nil)
        #expect(action.headers == nil)
        #expect(action.body == nil)
        #expect(action.clear == nil)
    }

    @Test("MessageAction initializes with all values")
    func init_allValues() {
        let action = MessageAction(
            action: "http",
            label: "POST Request",
            url: "https://api.example.com",
            method: "POST",
            headers: ["Authorization": "Bearer token"],
            body: "{\"key\":\"value\"}",
            clear: true
        )

        #expect(action.action == "http")
        #expect(action.label == "POST Request")
        #expect(action.url == "https://api.example.com")
        #expect(action.method == "POST")
        #expect(action.headers?["Authorization"] == "Bearer token")
        #expect(action.body == "{\"key\":\"value\"}")
        #expect(action.clear == true)
    }
}
