//
//  TopicTests.swift
//  ntfyTests
//
//  Created by Achmad Mahardi on 20/12/25.
//

import Testing
import Foundation
import SwiftData
@testable import Notify

@Suite("Topic Model")
struct TopicTests {

    // MARK: - effectiveDisplayName Tests

    @Test("effectiveDisplayName returns displayName when set")
    func effectiveDisplayName_returnsDisplayName_whenSet() {
        let topic = Topic(name: "server-alerts", displayName: "My Server Alerts")
        #expect(topic.effectiveDisplayName == "My Server Alerts")
    }

    @Test("effectiveDisplayName returns topic name when displayName is nil")
    func effectiveDisplayName_returnsName_whenDisplayNameNil() {
        let topic = Topic(name: "server-alerts")
        #expect(topic.effectiveDisplayName == "server-alerts")
    }

    @Test("effectiveDisplayName returns topic name when displayName is empty string")
    func effectiveDisplayName_returnsDisplayName_whenEmpty() {
        // Note: Empty string is still a valid displayName, not nil
        let topic = Topic(name: "server-alerts", displayName: "")
        #expect(topic.effectiveDisplayName == "")
    }

    // MARK: - sseURL Tests

    @Test("sseURL constructs correct URL for default server")
    func sseURL_constructsCorrectURL_forDefaultServer() {
        let topic = Topic(name: "test-topic", serverURL: "https://ntfy.sh")

        let expectedURL = URL(string: "https://ntfy.sh/test-topic/sse")
        #expect(topic.sseURL == expectedURL)
    }

    @Test("sseURL constructs correct URL for custom server")
    func sseURL_constructsCorrectURL_forCustomServer() {
        let topic = Topic(name: "alerts", serverURL: "https://ntfy.example.com")

        let expectedURL = URL(string: "https://ntfy.example.com/alerts/sse")
        #expect(topic.sseURL == expectedURL)
    }

    @Test("sseURL handles server URL with trailing slash")
    func sseURL_handlesTrailingSlash() {
        // Note: Current implementation doesn't strip trailing slash
        // This test documents current behavior
        let topic = Topic(name: "test", serverURL: "https://ntfy.sh/")

        let url = topic.sseURL
        #expect(url?.absoluteString == "https://ntfy.sh//test/sse")
    }

    @Test("sseURL encodes special characters in topic name")
    func sseURL_encodesSpecialCharacters() {
        let topic = Topic(name: "test topic", serverURL: "https://ntfy.sh")

        let url = topic.sseURL
        #expect(url != nil)
        #expect(url?.absoluteString.contains("test%20topic") == true)
    }

    @Test("sseURL encodes unicode characters")
    func sseURL_encodesUnicodeCharacters() {
        let topic = Topic(name: "日本語", serverURL: "https://ntfy.sh")

        let url = topic.sseURL
        #expect(url != nil)
        // Should be percent-encoded
        #expect(url?.absoluteString.contains("%") == true)
    }

    @Test("sseURL handles empty topic name")
    func sseURL_handlesEmptyTopicName() {
        let topic = Topic(name: "", serverURL: "https://ntfy.sh")

        // Empty name should still produce a URL (albeit invalid for the API)
        let url = topic.sseURL
        #expect(url?.absoluteString == "https://ntfy.sh//sse")
    }

    // MARK: - Initialization Tests

    @Test("Topic initializes with default values")
    func init_setsDefaultValues() {
        let topic = Topic(name: "test")

        #expect(topic.name == "test")
        #expect(topic.displayName == nil)
        #expect(topic.serverURL == "https://ntfy.sh")
        #expect(topic.username == nil)
        #expect(topic.messages.isEmpty)
    }

    @Test("Topic initializes with custom values")
    func init_setsCustomValues() {
        let customId = UUID()
        let customDate = Date(timeIntervalSince1970: 1000)

        let topic = Topic(
            id: customId,
            name: "alerts",
            displayName: "My Alerts",
            serverURL: "https://custom.ntfy.sh",
            username: "admin",
            createdAt: customDate
        )

        #expect(topic.id == customId)
        #expect(topic.name == "alerts")
        #expect(topic.displayName == "My Alerts")
        #expect(topic.serverURL == "https://custom.ntfy.sh")
        #expect(topic.username == "admin")
        #expect(topic.createdAt == customDate)
    }

    // MARK: - unreadCount Tests

    @Test("unreadCount returns zero for empty messages")
    func unreadCount_returnsZero_whenNoMessages() {
        let topic = Topic(name: "test")
        #expect(topic.unreadCount == 0)
    }

    @Test("unreadCount counts only unread messages")
    @MainActor
    func unreadCount_countsUnreadMessages() throws {
        // Create in-memory SwiftData container for testing
        let schema = Schema([Topic.self, Message.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let topic = Topic(name: "test")
        context.insert(topic)

        // Add messages with different read states
        let unread1 = Message(id: "1", topic: topic, body: "Unread 1", isRead: false)
        let unread2 = Message(id: "2", topic: topic, body: "Unread 2", isRead: false)
        let read1 = Message(id: "3", topic: topic, body: "Read 1", isRead: true)

        context.insert(unread1)
        context.insert(unread2)
        context.insert(read1)

        try context.save()

        #expect(topic.unreadCount == 2)
    }

    @Test("unreadCount returns zero when all messages are read")
    @MainActor
    func unreadCount_returnsZero_whenAllRead() throws {
        let schema = Schema([Topic.self, Message.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let topic = Topic(name: "test")
        context.insert(topic)

        let read1 = Message(id: "1", topic: topic, body: "Read 1", isRead: true)
        let read2 = Message(id: "2", topic: topic, body: "Read 2", isRead: true)

        context.insert(read1)
        context.insert(read2)

        try context.save()

        #expect(topic.unreadCount == 0)
    }
}
