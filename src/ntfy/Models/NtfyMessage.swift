//
//  NtfyMessage.swift
//  ntfy
//
//  Created by Achmad Mahardi on 19/12/25.
//

import Foundation

/// Represents a message received from the ntfy SSE connection
/// Marked nonisolated to allow decoding from non-main-actor contexts (e.g., inside actors)
nonisolated struct NtfyMessage: Codable, Sendable {
    let id: String
    let time: Int
    let event: NtfyEvent
    let topic: String
    let message: String?
    let title: String?
    let priority: Int?
    let tags: [String]?
    let click: String?
    let actions: [NtfyAction]?
    let attachment: NtfyAttachment?

    var date: Date {
        Date(timeIntervalSince1970: TimeInterval(time))
    }
}

nonisolated enum NtfyEvent: String, Codable, Sendable {
    case open
    case keepalive
    case message
    case pollRequest = "poll_request"
}

nonisolated struct NtfyAction: Codable, Sendable {
    let action: String
    let label: String
    let url: String?
    let method: String?
    let headers: [String: String]?
    let body: String?
    let clear: Bool?

    func toMessageAction() -> MessageAction {
        MessageAction(
            action: action,
            label: label,
            url: url,
            method: method,
            headers: headers,
            body: body,
            clear: clear
        )
    }
}

nonisolated struct NtfyAttachment: Codable, Sendable {
    let name: String
    let type: String?
    let size: Int?
    let expires: Int?
    let url: String
}
