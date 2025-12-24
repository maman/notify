//
//  Topic.swift
//  ntfy
//
//  Created by Achmad Mahardi on 19/12/25.
//

import Foundation
import SwiftData

@Model
final class Topic {
    @Attribute(.unique) var id: UUID
    var name: String
    var displayName: String?
    var serverURL: String
    var username: String?
    // Password stored in Keychain via KeychainService, keyed by topic.id
    var createdAt: Date

    /// Indicates if this topic is managed by MDM (cannot be deleted by user)
    var isManagedByMDM: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \Message.topic)
    var messages: [Message] = []

    init(
        id: UUID = UUID(),
        name: String,
        displayName: String? = nil,
        serverURL: String = "https://ntfy.sh",
        username: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.serverURL = serverURL
        self.username = username
        self.createdAt = createdAt
    }

    var effectiveDisplayName: String {
        displayName ?? name
    }

    /// SSE (Server-Sent Events) URL for battery-efficient streaming
    var sseURL: URL? {
        guard let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            return nil
        }
        return URL(string: "\(serverURL)/\(encodedName)/sse")
    }

    var unreadCount: Int {
        // More efficient implementation using lazy evaluation
        messages.lazy.filter { !$0.isRead }.count
    }
}
