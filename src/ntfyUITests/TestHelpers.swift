//
//  TestHelpers.swift
//  ntfyUITests
//
//  Created by Achmad Mahardi on 20/12/25.
//

import XCTest

/// Base test case class with common setup and helpers for ntfy UI tests
class NtfyUITestCase: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Reset "hasLaunchedBefore" to ensure topics window opens
        // Using launch arguments to set UserDefaults value to NO
        app.launchArguments = ["--uitesting", "-hasLaunchedBefore", "NO"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Window Helpers

    /// The main topics window
    var topicsWindow: XCUIElement {
        app.windows["topics"]
    }

    /// Wait for the topics window to appear
    @MainActor
    func waitForTopicsWindow(timeout: TimeInterval = 5) -> Bool {
        topicsWindow.waitForExistence(timeout: timeout)
    }

    // MARK: - Navigation Helpers

    /// The topics list in the sidebar
    var topicsList: XCUIElement {
        app.outlines["topicsList"]
    }

    /// The add topic button in the toolbar
    var addTopicButton: XCUIElement {
        app.buttons["addTopicButton"].firstMatch
    }

    /// The empty topics view when no topics are subscribed
    var emptyTopicsView: XCUIElement {
        app.staticTexts["No Topics"]
    }

    // MARK: - New Topic Form Helpers

    /// The topic name text field
    var topicNameField: XCUIElement {
        app.textFields["topicNameField"]
    }

    /// The randomize button for generating random topic names
    var randomizeButton: XCUIElement {
        app.buttons["randomizeButton"].firstMatch
    }

    /// The subscribe button in the new topic form
    var subscribeButton: XCUIElement {
        app.buttons["subscribeButton"].firstMatch
    }

    /// The cancel button in the new topic form
    var cancelButton: XCUIElement {
        app.buttons["cancelButton"].firstMatch
    }

    /// The custom server toggle
    var customServerToggle: XCUIElement {
        app.checkBoxes["customServerToggle"]
    }

    /// The server URL text field
    var serverURLField: XCUIElement {
        app.textFields["serverURLField"]
    }

    /// The auth toggle
    var authToggle: XCUIElement {
        app.checkBoxes["authToggle"]
    }

    // MARK: - Message List Helpers

    /// The messages list
    var messagesList: XCUIElement {
        app.scrollViews["messagesList"]
    }

    /// The empty messages view
    var emptyMessagesView: XCUIElement {
        app.staticTexts["No Messages"]
    }

    /// The actions menu in the toolbar
    var actionsMenu: XCUIElement {
        app.menuButtons["actionsMenu"].firstMatch
    }

    // MARK: - Topic Row Helpers

    /// Get a topic row by UUID
    func topicRow(id: String) -> XCUIElement {
        app.cells.matching(identifier: "topicRow-\(id)").firstMatch
    }

    /// Get the connection indicator for a topic
    func connectionIndicator(topicId: String) -> XCUIElement {
        app.images["connectionIndicator-\(topicId)"]
    }

    /// Get the unread badge for a topic
    func unreadBadge(topicId: String) -> XCUIElement {
        app.staticTexts["unreadBadge-\(topicId)"]
    }

    // MARK: - Message Row Helpers

    /// Get a message row by ID
    func messageRow(id: String) -> XCUIElement {
        app.otherElements["messageRow-\(id)"]
    }

    /// Get the mark read button for a message
    func markReadButton(messageId: String) -> XCUIElement {
        app.buttons["markReadButton-\(messageId)"].firstMatch
    }

    /// Get the delete button for a message
    func deleteButton(messageId: String) -> XCUIElement {
        app.buttons["deleteButton-\(messageId)"].firstMatch
    }

    // MARK: - Subscription Flow Helpers

    /// Subscribe to a topic with the given name
    @MainActor
    func subscribeTo(topicName: String) {
        // Tap add button
        addTopicButton.tap()

        // Wait for form to appear
        _ = topicNameField.waitForExistence(timeout: 2)

        // Enter topic name
        topicNameField.tap()
        topicNameField.typeText(topicName)

        // Submit
        subscribeButton.tap()
    }

    /// Unsubscribe from a topic by right-clicking and selecting unsubscribe
    @MainActor
    func unsubscribeFrom(topicRow: XCUIElement) {
        topicRow.rightClick()

        // Wait for context menu
        let unsubscribeItem = app.menuItems["Unsubscribe"]
        _ = unsubscribeItem.waitForExistence(timeout: 2)
        unsubscribeItem.tap()

        // Confirm in alert
        let confirmButton = app.buttons["Unsubscribe"]
        _ = confirmButton.waitForExistence(timeout: 2)
        confirmButton.tap()
    }

    // MARK: - Wait Helpers

    /// Wait for an element to exist with a custom timeout
    @MainActor
    func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 3) -> Bool {
        element.waitForExistence(timeout: timeout)
    }

    /// Wait for an element to not exist (be removed)
    @MainActor
    func waitForElementToDisappear(_ element: XCUIElement, timeout: TimeInterval = 3) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
}

// MARK: - XCUIElement Extensions

extension XCUIElement {
    /// Clear existing text in a text field and type new text
    func clearAndTypeText(_ text: String) {
        guard exists else { return }
        tap()

        // Select all and delete
        typeKey("a", modifierFlags: .command)
        typeKey(.delete, modifierFlags: [])

        // Type new text
        typeText(text)
    }
}
