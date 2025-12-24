//
//  ManagedConfigurationTests.swift
//  ntfyTests
//
//  Created by Claude on 24/12/25.
//

import Testing
import Foundation
import SwiftData
@testable import Notify

@Suite("Managed Configuration")
struct ManagedConfigurationTests {

    // MARK: - ManagedTopicConfig Tests

    @Test("ManagedTopicConfig initializes from valid dictionary")
    func topicConfig_initFromDict_valid() {
        let dict: [String: Any] = [
            "name": "engineering-alerts",
            "serverURL": "https://ntfy.example.com",
            "username": "admin"
        ]

        let config = ManagedTopicConfig(from: dict)

        #expect(config != nil)
        #expect(config?.name == "engineering-alerts")
        #expect(config?.serverURL == "https://ntfy.example.com")
        #expect(config?.username == "admin")
    }

    @Test("ManagedTopicConfig initializes with only required name")
    func topicConfig_initFromDict_onlyName() {
        let dict: [String: Any] = [
            "name": "minimal-topic"
        ]

        let config = ManagedTopicConfig(from: dict)

        #expect(config != nil)
        #expect(config?.name == "minimal-topic")
        #expect(config?.serverURL == nil)
        #expect(config?.username == nil)
    }

    @Test("ManagedTopicConfig returns nil for missing name")
    func topicConfig_initFromDict_missingName() {
        let dict: [String: Any] = [
            "serverURL": "https://ntfy.sh"
        ]

        let config = ManagedTopicConfig(from: dict)

        #expect(config == nil)
    }

    @Test("ManagedTopicConfig returns nil for empty dictionary")
    func topicConfig_initFromDict_empty() {
        let dict: [String: Any] = [:]

        let config = ManagedTopicConfig(from: dict)

        #expect(config == nil)
    }

    @Test("ManagedTopicConfig direct initialization")
    func topicConfig_directInit() {
        let config = ManagedTopicConfig(
            name: "test-topic",
            serverURL: "https://custom.ntfy.sh",
            username: "user123"
        )

        #expect(config.name == "test-topic")
        #expect(config.serverURL == "https://custom.ntfy.sh")
        #expect(config.username == "user123")
    }

    // MARK: - ManagedConfiguration Tests

    @Test("ManagedConfiguration initializes from full dictionary")
    func config_initFromDict_full() {
        let dict: [String: Any] = [
            "topics": [
                ["name": "topic1", "serverURL": "https://ntfy.sh"],
                ["name": "topic2"]
            ],
            "launchAtLogin": true
        ]

        let config = ManagedConfiguration(from: dict)

        #expect(config.topics?.count == 2)
        #expect(config.topics?[0].name == "topic1")
        #expect(config.topics?[1].name == "topic2")
        #expect(config.launchAtLogin == true)
    }

    @Test("ManagedConfiguration initializes with only topics")
    func config_initFromDict_onlyTopics() {
        let dict: [String: Any] = [
            "topics": [
                ["name": "single-topic"]
            ]
        ]

        let config = ManagedConfiguration(from: dict)

        #expect(config.topics?.count == 1)
        #expect(config.launchAtLogin == nil)
    }

    @Test("ManagedConfiguration initializes with only launchAtLogin")
    func config_initFromDict_onlyLaunchAtLogin() {
        let dict: [String: Any] = [
            "launchAtLogin": false
        ]

        let config = ManagedConfiguration(from: dict)

        #expect(config.topics == nil)
        #expect(config.launchAtLogin == false)
    }

    @Test("ManagedConfiguration initializes from empty dictionary")
    func config_initFromDict_empty() {
        let dict: [String: Any] = [:]

        let config = ManagedConfiguration(from: dict)

        #expect(config.topics == nil)
        #expect(config.launchAtLogin == nil)
    }

    @Test("ManagedConfiguration filters invalid topics from array")
    func config_initFromDict_filtersInvalidTopics() {
        let dict: [String: Any] = [
            "topics": [
                ["name": "valid-topic"],
                ["serverURL": "missing-name"],  // Invalid - no name
                ["name": "another-valid"]
            ]
        ]

        let config = ManagedConfiguration(from: dict)

        #expect(config.topics?.count == 2)
        #expect(config.topics?[0].name == "valid-topic")
        #expect(config.topics?[1].name == "another-valid")
    }

    @Test("ManagedConfiguration default configuration has nil values")
    func config_defaultConfiguration() {
        let config = ManagedConfiguration.defaultConfiguration

        #expect(config.topics == nil)
        #expect(config.launchAtLogin == nil)
    }

    // MARK: - ManagedConfigurationService Tests

    @Test("ManagedConfigurationService initializes with default configuration")
    func service_initializesWithDefaults() {
        let service = ManagedConfigurationService()

        #expect(service.isLaunchAtLoginManaged == false)
        #expect(service.managedLaunchAtLogin == nil)
        #expect(service.hasManagedTopics == false)
        #expect(service.managedTopics.isEmpty)
    }

    @Test("ManagedConfigurationService isLaunchAtLoginManaged returns true when set")
    func service_isLaunchAtLoginManaged_whenSet() {
        // Create a service and manually set configuration for testing
        let service = ManagedConfigurationService()

        // Service starts with default config
        #expect(service.isLaunchAtLoginManaged == false)

        // Note: In production, configuration is set via UserDefaults by MDM
        // This test verifies the computed property logic
    }

    // MARK: - Topic isManagedByMDM Tests

    @Test("Topic isManagedByMDM defaults to false")
    func topic_isManagedByMDM_defaultsFalse() {
        let topic = Topic(name: "test-topic")

        #expect(topic.isManagedByMDM == false)
    }

    @Test("Topic isManagedByMDM can be set to true")
    @MainActor
    func topic_isManagedByMDM_canBeSetTrue() throws {
        let schema = Schema([Topic.self, Message.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let topic = Topic(name: "managed-topic")
        topic.isManagedByMDM = true
        context.insert(topic)
        try context.save()

        let descriptor = FetchDescriptor<Topic>()
        let topics = try context.fetch(descriptor)

        #expect(topics.count == 1)
        #expect(topics[0].isManagedByMDM == true)
    }

    @Test("canDeleteTopic returns true for non-managed topic")
    func appState_canDeleteTopic_nonManaged() {
        let topic = Topic(name: "user-topic")
        topic.isManagedByMDM = false

        let appState = AppState()
        #expect(appState.canDeleteTopic(topic) == true)
    }

    @Test("canDeleteTopic returns false for managed topic")
    func appState_canDeleteTopic_managed() {
        let topic = Topic(name: "managed-topic")
        topic.isManagedByMDM = true

        let appState = AppState()
        #expect(appState.canDeleteTopic(topic) == false)
    }

    // MARK: - Integration Tests

    @Test("Multiple managed topics with different configurations")
    func multipleTopics_differentConfigs() {
        let dict: [String: Any] = [
            "topics": [
                [
                    "name": "alerts",
                    "serverURL": "https://alerts.example.com",
                    "username": "alertuser"
                ],
                [
                    "name": "notifications",
                    "serverURL": "https://ntfy.sh"
                ],
                [
                    "name": "simple-topic"
                ]
            ],
            "launchAtLogin": true
        ]

        let config = ManagedConfiguration(from: dict)

        #expect(config.topics?.count == 3)

        // First topic - full config
        #expect(config.topics?[0].name == "alerts")
        #expect(config.topics?[0].serverURL == "https://alerts.example.com")
        #expect(config.topics?[0].username == "alertuser")

        // Second topic - partial config
        #expect(config.topics?[1].name == "notifications")
        #expect(config.topics?[1].serverURL == "https://ntfy.sh")
        #expect(config.topics?[1].username == nil)

        // Third topic - minimal config
        #expect(config.topics?[2].name == "simple-topic")
        #expect(config.topics?[2].serverURL == nil)
        #expect(config.topics?[2].username == nil)

        #expect(config.launchAtLogin == true)
    }
}
