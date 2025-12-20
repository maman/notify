//
//  TopicTests.swift
//  ntfyUITests
//
//  Created by Achmad Mahardi on 20/12/25.
//

import XCTest

/// UI tests for topic management functionality
final class TopicTests: NtfyUITestCase {

    // MARK: - P0: Core Flows

    @MainActor
    func testAddTopic_withValidName_createsTopic() throws {
        // Verify window appears
        XCTAssertTrue(waitForTopicsWindow(), "Topics window should appear")

        // Tap add topic button
        XCTAssertTrue(addTopicButton.exists, "Add topic button should exist")
        addTopicButton.tap()

        // Wait for form
        XCTAssertTrue(topicNameField.waitForExistence(timeout: 2), "Topic name field should appear")

        // Enter topic name
        let testTopicName = "uitest-\(Int.random(in: 1000...9999))"
        topicNameField.tap()
        topicNameField.typeText(testTopicName)

        // Verify subscribe button is enabled
        XCTAssertTrue(subscribeButton.isEnabled, "Subscribe button should be enabled with valid name")

        // Subscribe
        subscribeButton.tap()

        // Verify topic appears in list (check for the topic name text)
        let topicText = app.staticTexts[testTopicName].firstMatch
        XCTAssertTrue(topicText.waitForExistence(timeout: 3), "New topic should appear in list")
    }

    @MainActor
    func testAddTopic_emptyName_disablesSubscribe() throws {
        // Verify window appears
        XCTAssertTrue(waitForTopicsWindow(), "Topics window should appear")

        // Tap add topic button
        addTopicButton.tap()

        // Wait for form
        XCTAssertTrue(topicNameField.waitForExistence(timeout: 2), "Topic name field should appear")

        // Verify subscribe button is disabled with empty field
        XCTAssertFalse(subscribeButton.isEnabled, "Subscribe button should be disabled with empty name")

        // Type something then clear it
        topicNameField.tap()
        topicNameField.typeText("test")
        XCTAssertTrue(subscribeButton.isEnabled, "Subscribe button should be enabled")

        // Clear the field
        topicNameField.clearAndTypeText("")
        XCTAssertFalse(subscribeButton.isEnabled, "Subscribe button should be disabled after clearing")
    }

    @MainActor
    func testAddTopic_randomize_generatesName() throws {
        // Verify window appears
        XCTAssertTrue(waitForTopicsWindow(), "Topics window should appear")

        // Tap add topic button
        addTopicButton.tap()

        // Wait for form
        XCTAssertTrue(topicNameField.waitForExistence(timeout: 2), "Topic name field should appear")

        // Get initial value (should be empty)
        let initialValue = topicNameField.value as? String ?? ""
        XCTAssertTrue(initialValue.isEmpty, "Topic name should initially be empty")

        // Tap randomize
        randomizeButton.tap()

        // Verify field now has a value
        let newValue = topicNameField.value as? String ?? ""
        XCTAssertFalse(newValue.isEmpty, "Topic name should have a random value after randomize")

        // Verify subscribe is now enabled
        XCTAssertTrue(subscribeButton.isEnabled, "Subscribe button should be enabled after randomize")
    }

    @MainActor
    func testDeleteTopic_confirmsAndRemoves() throws {
        // First subscribe to a topic
        XCTAssertTrue(waitForTopicsWindow(), "Topics window should appear")

        let testTopicName = "delete-test-\(Int.random(in: 1000...9999))"
        subscribeTo(topicName: testTopicName)

        // Wait for topic to appear in sidebar
        let sidebar = app.outlines["topicsList"]
        XCTAssertTrue(sidebar.waitForExistence(timeout: 3), "Sidebar should exist")

        let topicRow = sidebar.staticTexts[testTopicName].firstMatch
        XCTAssertTrue(topicRow.waitForExistence(timeout: 3), "Topic should appear in sidebar after subscribing")

        // Right-click on the topic row to open context menu
        topicRow.rightClick()

        // Wait for context menu and click Unsubscribe
        let unsubscribeMenuItem = app.menuItems["Unsubscribe"]
        XCTAssertTrue(unsubscribeMenuItem.waitForExistence(timeout: 2), "Unsubscribe menu item should appear")
        unsubscribeMenuItem.tap()

        // Wait for confirmation dialog and click Unsubscribe button
        // SwiftUI alerts may appear as dialogs or sheets - look for the button directly
        let confirmButton = app.buttons["Unsubscribe"].firstMatch
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 2), "Unsubscribe confirmation button should appear")
        confirmButton.tap()

        // Verify topic is removed from sidebar
        XCTAssertTrue(waitForElementToDisappear(topicRow), "Topic should be removed after unsubscribe")
    }

    @MainActor
    func testCancelAddTopic_dismissesForm() throws {
        // Verify window appears
        XCTAssertTrue(waitForTopicsWindow(), "Topics window should appear")

        // Tap add topic button
        addTopicButton.tap()

        // Wait for form
        XCTAssertTrue(topicNameField.waitForExistence(timeout: 2), "Topic name field should appear")

        // Enter a topic name
        topicNameField.tap()
        topicNameField.typeText("cancel-test")

        // Tap cancel
        cancelButton.tap()

        // Verify form is dismissed (topic name field should disappear or be replaced)
        // The form should close and show the no-topic-selected view or topic list
        let noSelectionView = app.staticTexts["Select a Topic"].firstMatch
        let formDismissed = noSelectionView.waitForExistence(timeout: 2) || !topicNameField.exists
        XCTAssertTrue(formDismissed, "Form should be dismissed after cancel")
    }

    // MARK: - P1: Secondary Flows

    @MainActor
    func testSelectTopic_showsMessagesView() throws {
        // First subscribe to a topic
        XCTAssertTrue(waitForTopicsWindow(), "Topics window should appear")

        let testTopicName = "select-test-\(Int.random(in: 1000...9999))"
        subscribeTo(topicName: testTopicName)

        // Wait for topic to appear
        let topicText = app.staticTexts[testTopicName].firstMatch
        XCTAssertTrue(topicText.waitForExistence(timeout: 3), "Topic should appear after subscribing")

        // Topic should be auto-selected, check for empty messages view
        let noMessages = app.staticTexts["No Messages"].firstMatch
        XCTAssertTrue(noMessages.waitForExistence(timeout: 2), "Should show No Messages for new topic")
    }

    @MainActor
    func testRenameTopic_updatesDisplay() throws {
        // First subscribe to a topic
        XCTAssertTrue(waitForTopicsWindow(), "Topics window should appear")

        let originalName = "rename-orig-\(Int.random(in: 1000...9999))"
        subscribeTo(topicName: originalName)

        // Wait for topic to appear in sidebar
        let sidebar = app.outlines["topicsList"]
        XCTAssertTrue(sidebar.waitForExistence(timeout: 3), "Sidebar should exist")

        let topicRow = sidebar.staticTexts[originalName].firstMatch
        XCTAssertTrue(topicRow.waitForExistence(timeout: 3), "Topic should appear in sidebar after subscribing")

        // Right-click to open context menu
        topicRow.rightClick()

        // Click Rename
        let renameMenuItem = app.menuItems["Rename..."].firstMatch
        XCTAssertTrue(renameMenuItem.waitForExistence(timeout: 2), "Rename menu item should appear")
        renameMenuItem.tap()

        // Wait for rename dialog text field to appear
        // SwiftUI alerts may appear as dialogs or sheets - look for elements directly
        let textField = app.textFields["Display Name"].firstMatch
        XCTAssertTrue(textField.waitForExistence(timeout: 2), "Rename text field should appear")

        // Enter new display name
        let newDisplayName = "Renamed Topic"
        textField.tap()
        textField.typeText(newDisplayName)

        // Confirm rename
        let renameButton = app.buttons["Rename"].firstMatch
        XCTAssertTrue(renameButton.waitForExistence(timeout: 2), "Rename button should exist")
        renameButton.tap()

        // Verify new display name appears in the sidebar
        let newNameText = sidebar.staticTexts[newDisplayName].firstMatch
        XCTAssertTrue(newNameText.waitForExistence(timeout: 2), "Renamed display name should appear in sidebar")
    }
}
