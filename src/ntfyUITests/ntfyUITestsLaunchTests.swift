//
//  ntfyUITestsLaunchTests.swift
//  ntfyUITests
//
//  Created by Achmad Mahardi on 19/12/25.
//

import XCTest

/// Launch and startup tests for the ntfy app
final class LaunchTests: NtfyUITestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    @MainActor
    func testLaunch_windowAppears() throws {
        // Verify the topics window appears after launch
        XCTAssertTrue(waitForTopicsWindow(), "Topics window should appear after launch")

        // Take a screenshot
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testLaunch_addTopicButtonExists() throws {
        // Verify the add topic button exists
        XCTAssertTrue(waitForTopicsWindow(), "Topics window should appear")
        XCTAssertTrue(addTopicButton.exists, "Add topic button should exist after launch")
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch the application
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
