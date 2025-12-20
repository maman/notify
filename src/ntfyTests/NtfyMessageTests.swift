//
//  NtfyMessageTests.swift
//  ntfyTests
//
//  Created by Achmad Mahardi on 20/12/25.
//

import Testing
import Foundation
@testable import Notify

@Suite("NtfyMessage Decoding")
struct NtfyMessageTests {

    // MARK: - JSON Decoding Tests

    @Test("Decodes minimal message with only required fields")
    func decode_parsesMinimalMessage() throws {
        let data = TestFixtures.minimalMessageJSON.data(using: .utf8)!
        let message = try JSONDecoder().decode(NtfyMessage.self, from: data)

        #expect(message.id == "abc123")
        #expect(message.time == 1703001600)
        #expect(message.event == .message)
        #expect(message.topic == "test")
        #expect(message.message == nil)
        #expect(message.title == nil)
        #expect(message.priority == nil)
        #expect(message.tags == nil)
        #expect(message.click == nil)
        #expect(message.actions == nil)
        #expect(message.attachment == nil)
    }

    @Test("Decodes message with body text")
    func decode_parsesMessageWithBody() throws {
        let data = TestFixtures.messageWithBodyJSON.data(using: .utf8)!
        let message = try JSONDecoder().decode(NtfyMessage.self, from: data)

        #expect(message.id == "msg001")
        #expect(message.message == "Hello World")
        #expect(message.topic == "alerts")
    }

    @Test("Decodes full message with all optional fields")
    func decode_parsesFullMessage() throws {
        let data = TestFixtures.fullMessageJSON.data(using: .utf8)!
        let message = try JSONDecoder().decode(NtfyMessage.self, from: data)

        #expect(message.id == "msg123")
        #expect(message.time == 1703001600)
        #expect(message.event == .message)
        #expect(message.topic == "alerts")
        #expect(message.message == "Server is down")
        #expect(message.title == "Critical Alert")
        #expect(message.priority == 5)
        #expect(message.tags == ["warning", "server"])
        #expect(message.click == "https://example.com/status")
        #expect(message.actions?.count == 2)
        #expect(message.attachment != nil)
    }

    @Test("Decodes message with actions correctly")
    func decode_parsesActions() throws {
        let data = TestFixtures.messageWithActionsJSON.data(using: .utf8)!
        let message = try JSONDecoder().decode(NtfyMessage.self, from: data)

        #expect(message.actions?.count == 2)

        let firstAction = message.actions?[0]
        #expect(firstAction?.action == "view")
        #expect(firstAction?.label == "View")
        #expect(firstAction?.url == "https://example.com")

        let secondAction = message.actions?[1]
        #expect(secondAction?.action == "broadcast")
        #expect(secondAction?.label == "Share")
        #expect(secondAction?.url == nil)
    }

    @Test("Decodes message with attachment correctly")
    func decode_parsesAttachment() throws {
        let data = TestFixtures.messageWithAttachmentJSON.data(using: .utf8)!
        let message = try JSONDecoder().decode(NtfyMessage.self, from: data)

        let attachment = message.attachment
        #expect(attachment != nil)
        #expect(attachment?.name == "document.pdf")
        #expect(attachment?.type == "application/pdf")
        #expect(attachment?.size == 204800)
        #expect(attachment?.url == "https://ntfy.sh/file/doc123.pdf")
    }

    @Test("Decodes full message attachment with all fields")
    func decode_parsesFullAttachment() throws {
        let data = TestFixtures.fullMessageJSON.data(using: .utf8)!
        let message = try JSONDecoder().decode(NtfyMessage.self, from: data)

        let attachment = message.attachment
        #expect(attachment?.name == "screenshot.png")
        #expect(attachment?.type == "image/png")
        #expect(attachment?.size == 102400)
        #expect(attachment?.expires == 1703088000)
        #expect(attachment?.url == "https://ntfy.sh/file/abc123.png")
    }

    // MARK: - Event Type Tests

    @Test("Decodes open event correctly")
    func decode_parsesOpenEvent() throws {
        let data = TestFixtures.openEventJSON.data(using: .utf8)!
        let message = try JSONDecoder().decode(NtfyMessage.self, from: data)

        #expect(message.event == .open)
    }

    @Test("Decodes keepalive event correctly")
    func decode_parsesKeepaliveEvent() throws {
        let data = TestFixtures.keepaliveEventJSON.data(using: .utf8)!
        let message = try JSONDecoder().decode(NtfyMessage.self, from: data)

        #expect(message.event == .keepalive)
    }

    // MARK: - Date Computed Property Tests

    @Test("Converts Unix timestamp to Date correctly")
    func date_convertsUnixTimestamp() throws {
        let data = TestFixtures.minimalMessageJSON.data(using: .utf8)!
        let message = try JSONDecoder().decode(NtfyMessage.self, from: data)

        let expectedDate = Date(timeIntervalSince1970: 1703001600)
        #expect(message.date == expectedDate)
    }

    // MARK: - NtfyAction Conversion Tests

    @Test("Converts NtfyAction to MessageAction correctly")
    func toMessageAction_convertsCorrectly() throws {
        let data = TestFixtures.fullMessageJSON.data(using: .utf8)!
        let message = try JSONDecoder().decode(NtfyMessage.self, from: data)

        guard let ntfyAction = message.actions?.last else {
            Issue.record("Expected actions to be present")
            return
        }

        let messageAction = ntfyAction.toMessageAction()

        #expect(messageAction.action == "http")
        #expect(messageAction.label == "Restart Server")
        #expect(messageAction.url == "https://api.example.com/restart")
        #expect(messageAction.method == "POST")
        #expect(messageAction.headers?["Authorization"] == "Bearer token123")
        #expect(messageAction.body == "{}")
        #expect(messageAction.clear == true)
    }

    @Test("Converts minimal NtfyAction to MessageAction")
    func toMessageAction_handlesMinimalAction() throws {
        let data = TestFixtures.messageWithActionsJSON.data(using: .utf8)!
        let message = try JSONDecoder().decode(NtfyMessage.self, from: data)

        guard let ntfyAction = message.actions?.last else {
            Issue.record("Expected actions to be present")
            return
        }

        let messageAction = ntfyAction.toMessageAction()

        #expect(messageAction.action == "broadcast")
        #expect(messageAction.label == "Share")
        #expect(messageAction.url == nil)
        #expect(messageAction.method == nil)
        #expect(messageAction.headers == nil)
        #expect(messageAction.body == nil)
        #expect(messageAction.clear == nil)
    }
}
