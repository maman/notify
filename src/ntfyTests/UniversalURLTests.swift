//
//  UniversalURLTests.swift
//  ntfyTests
//
//  Created by Claude on 24/12/25.
//

import Testing
import Foundation
import SwiftData
@testable import Notify

@Suite("Universal URL Support")
struct UniversalURLTests {

    // MARK: - URL Parsing Tests

    @Test("URL with ntfy scheme extracts topic name from host")
    func urlParsing_extractsTopicName_fromHost() {
        let url = URL(string: "ntfy://my-topic")!

        #expect(url.scheme == "ntfy")
        #expect(url.host == "my-topic")
    }

    @Test("URL with random topic ID extracts correctly")
    func urlParsing_extractsRandomTopicId() {
        let url = URL(string: "ntfy://curut")!

        #expect(url.scheme == "ntfy")
        #expect(url.host == "curut")
    }

    @Test("URL with hyphenated topic name extracts correctly")
    func urlParsing_extractsHyphenatedTopicName() {
        let url = URL(string: "ntfy://nenk-spog-samp")!

        #expect(url.scheme == "ntfy")
        #expect(url.host == "nenk-spog-samp")
    }

    @Test("URL with different scheme returns nil host for ntfy check")
    func urlParsing_differentScheme_notNtfy() {
        let url = URL(string: "https://ntfy.sh/topic")!

        #expect(url.scheme != "ntfy")
    }

    @Test("URL without host returns nil")
    func urlParsing_noHost_returnsNil() {
        // ntfy:// with no host
        let url = URL(string: "ntfy://")!

        // Empty host may be nil or empty string depending on URL parsing
        let host = url.host
        #expect(host == nil || host?.isEmpty == true)
    }

    // MARK: - Topic Lookup Tests

    @Test("Topic lookup finds topic by exact name match")
    @MainActor
    func topicLookup_findsByExactName() throws {
        let schema = Schema([Topic.self, Message.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let topic1 = Topic(name: "engineering-alerts")
        let topic2 = Topic(name: "sales-updates")
        context.insert(topic1)
        context.insert(topic2)
        try context.save()

        let topics = try context.fetch(FetchDescriptor<Topic>())
        let foundTopic = topics.first { $0.name == "engineering-alerts" }

        #expect(foundTopic != nil)
        #expect(foundTopic?.name == "engineering-alerts")
    }

    @Test("Topic lookup returns nil for non-existent topic")
    @MainActor
    func topicLookup_returnsNil_forNonExistentTopic() throws {
        let schema = Schema([Topic.self, Message.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let topic = Topic(name: "existing-topic")
        context.insert(topic)
        try context.save()

        let topics = try context.fetch(FetchDescriptor<Topic>())
        let foundTopic = topics.first { $0.name == "non-existent-topic" }

        #expect(foundTopic == nil)
    }

    @Test("Topic lookup is case-sensitive")
    @MainActor
    func topicLookup_isCaseSensitive() throws {
        let schema = Schema([Topic.self, Message.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let topic = Topic(name: "MyTopic")
        context.insert(topic)
        try context.save()

        let topics = try context.fetch(FetchDescriptor<Topic>())

        // Exact match should work
        let exactMatch = topics.first { $0.name == "MyTopic" }
        #expect(exactMatch != nil)

        // Different case should not match
        let lowercaseMatch = topics.first { $0.name == "mytopic" }
        #expect(lowercaseMatch == nil)
    }

    // MARK: - URL Format Validation Tests

    @Test("Various valid ntfy URL formats")
    func urlFormats_variousValidFormats() {
        let validURLs = [
            "ntfy://simple",
            "ntfy://with-hyphens",
            "ntfy://with_underscores",
            "ntfy://MixedCase123",
            "ntfy://FFszGLa9wgFEOd6a",
        ]

        for urlString in validURLs {
            let url = URL(string: urlString)
            #expect(url != nil, "URL should be valid: \(urlString)")
            #expect(url?.scheme == "ntfy", "Scheme should be ntfy: \(urlString)")
            #expect(url?.host != nil, "Host should not be nil: \(urlString)")
        }
    }
}
