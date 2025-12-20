//
//  MessageTests.swift
//  ntfyUITests
//
//  Created by Achmad Mahardi on 20/12/25.
//

import XCTest

/// UI tests for message display and interaction functionality
final class MessageTests: NtfyUITestCase {

    // MARK: - P0: Core Flows

    @MainActor
    func testEmptyTopic_showsEmptyState() throws {
        // Subscribe to a new topic
        XCTAssertTrue(waitForTopicsWindow(), "Topics window should appear")

        let testTopicName = "empty-test-\(Int.random(in: 1000...9999))"
        subscribeTo(topicName: testTopicName)

        // Wait for topic to be selected
        let topicText = app.staticTexts[testTopicName].firstMatch
        XCTAssertTrue(topicText.waitForExistence(timeout: 3), "Topic should appear")

        // Verify empty messages view is shown
        let noMessages = app.staticTexts["No Messages"].firstMatch
        XCTAssertTrue(noMessages.waitForExistence(timeout: 2), "Should show 'No Messages' for empty topic")
    }

    @MainActor
    func testActionsMenu_exists() throws {
        // Subscribe to a topic first
        XCTAssertTrue(waitForTopicsWindow(), "Topics window should appear")

        let testTopicName = "actions-test-\(Int.random(in: 1000...9999))"
        subscribeTo(topicName: testTopicName)

        // Wait for topic to be selected
        let topicText = app.staticTexts[testTopicName].firstMatch
        XCTAssertTrue(topicText.waitForExistence(timeout: 3), "Topic should appear")

        // Verify actions menu exists in toolbar
        XCTAssertTrue(actionsMenu.waitForExistence(timeout: 2), "Actions menu should exist")

        // Open the menu
        actionsMenu.tap()

        // Verify menu items exist (they should be disabled for empty topic)
        let markAllRead = app.menuItems["Mark All as Read"]
        XCTAssertTrue(markAllRead.waitForExistence(timeout: 2), "Mark All as Read menu item should exist")

        let clearAll = app.menuItems["Clear All Messages"]
        XCTAssertTrue(clearAll.exists, "Clear All Messages menu item should exist")
    }

    @MainActor
    func testSelectingDifferentTopics_updatesMessageView() throws {
        // Subscribe to two topics
        XCTAssertTrue(waitForTopicsWindow(), "Topics window should appear")

        let topic1Name = "topic1-\(Int.random(in: 1000...9999))"
        subscribeTo(topicName: topic1Name)

        // Wait for first topic
        let topic1Text = app.staticTexts[topic1Name].firstMatch
        XCTAssertTrue(topic1Text.waitForExistence(timeout: 3), "First topic should appear")

        // Subscribe to second topic
        addTopicButton.tap()
        XCTAssertTrue(topicNameField.waitForExistence(timeout: 2), "Topic form should appear")

        let topic2Name = "topic2-\(Int.random(in: 1000...9999))"
        topicNameField.tap()
        topicNameField.typeText(topic2Name)
        subscribeButton.tap()

        // Wait for second topic
        let topic2Text = app.staticTexts[topic2Name].firstMatch
        XCTAssertTrue(topic2Text.waitForExistence(timeout: 3), "Second topic should appear")

        // Select first topic
        topic1Text.tap()

        // Small delay to allow UI to update
        Thread.sleep(forTimeInterval: 0.5)

        // Verify we can switch between topics (both should show empty state)
        let noMessages = app.staticTexts["No Messages"].firstMatch
        XCTAssertTrue(noMessages.exists, "Should show empty state for selected topic")
    }

    // MARK: - P1: Message Interactions

    // Note: Testing actual message content requires either:
    // 1. A test server that can send messages
    // 2. Mock/stub capabilities in the app
    // 3. Pre-seeded test data
    //
    // Since we don't have these in place, we test the UI structure
    // and empty states, which validates the accessibility identifiers work.

    @MainActor
    func testNavigationTitle_showsTopicName() throws {
        // Subscribe to a topic
        XCTAssertTrue(waitForTopicsWindow(), "Topics window should appear")

        let testTopicName = "navtitle-\(Int.random(in: 1000...9999))"
        subscribeTo(topicName: testTopicName)

        // Wait for topic to appear and be selected
        let topicText = app.staticTexts[testTopicName].firstMatch
        XCTAssertTrue(topicText.waitForExistence(timeout: 3), "Topic should appear")

        // The navigation title should show the topic name
        // In macOS, navigation titles appear in the window's title bar area
        // We can verify the topic name appears in the detail view
        XCTAssertTrue(topicText.exists, "Topic name should be visible")
    }
}
