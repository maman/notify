//
//  TestFixtures.swift
//  ntfyTests
//
//  Created by Achmad Mahardi on 20/12/25.
//

import Foundation

/// Test fixtures containing sample JSON and test data for unit tests
enum TestFixtures {

    // MARK: - NtfyMessage JSON Fixtures

    /// Minimal valid message JSON with only required fields
    static let minimalMessageJSON = """
    {"id":"abc123","time":1703001600,"event":"message","topic":"test"}
    """

    /// Message with body text
    static let messageWithBodyJSON = """
    {"id":"msg001","time":1703001600,"event":"message","topic":"alerts","message":"Hello World"}
    """

    /// Full message JSON with all optional fields
    static let fullMessageJSON = """
    {
        "id": "msg123",
        "time": 1703001600,
        "event": "message",
        "topic": "alerts",
        "message": "Server is down",
        "title": "Critical Alert",
        "priority": 5,
        "tags": ["warning", "server"],
        "click": "https://example.com/status",
        "actions": [
            {
                "action": "view",
                "label": "Open Dashboard",
                "url": "https://example.com/dashboard"
            },
            {
                "action": "http",
                "label": "Restart Server",
                "url": "https://api.example.com/restart",
                "method": "POST",
                "headers": {"Authorization": "Bearer token123"},
                "body": "{}",
                "clear": true
            }
        ],
        "attachment": {
            "name": "screenshot.png",
            "type": "image/png",
            "size": 102400,
            "expires": 1703088000,
            "url": "https://ntfy.sh/file/abc123.png"
        }
    }
    """

    /// Message with actions only
    static let messageWithActionsJSON = """
    {
        "id": "action001",
        "time": 1703001600,
        "event": "message",
        "topic": "test",
        "message": "Click to proceed",
        "actions": [
            {"action": "view", "label": "View", "url": "https://example.com"},
            {"action": "broadcast", "label": "Share"}
        ]
    }
    """

    /// Message with attachment only
    static let messageWithAttachmentJSON = """
    {
        "id": "attach001",
        "time": 1703001600,
        "event": "message",
        "topic": "files",
        "message": "New file uploaded",
        "attachment": {
            "name": "document.pdf",
            "type": "application/pdf",
            "size": 204800,
            "url": "https://ntfy.sh/file/doc123.pdf"
        }
    }
    """

    /// Open event (not a message)
    static let openEventJSON = """
    {"id":"evt001","time":1703001600,"event":"open","topic":"test"}
    """

    /// Keepalive event
    static let keepaliveEventJSON = """
    {"id":"evt002","time":1703001600,"event":"keepalive","topic":"test"}
    """

    // MARK: - Timestamps

    /// Unix timestamp: December 19, 2023 12:00:00 PM UTC
    static let sampleTimestamp: Int = 1703001600

    /// Expected Date for sampleTimestamp
    static let sampleDate: Date = Date(timeIntervalSince1970: 1703001600)

    // MARK: - Topic Fixtures

    static let defaultServerURL = "https://ntfy.sh"
    static let customServerURL = "https://ntfy.example.com"

    // MARK: - Priority Icons

    static let priorityIconMapping: [(priority: Int, icon: String)] = [
        (5, "exclamationmark.triangle.fill"),  // High/Urgent
        (4, "exclamationmark.circle.fill"),    // Medium-high
        (3, "bell"),                            // Normal (default)
        (2, "arrow.down.circle"),              // Low
        (1, "minus.circle"),                   // Very low
    ]
}
