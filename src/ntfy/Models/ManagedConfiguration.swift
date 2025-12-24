//
//  ManagedConfiguration.swift
//  ntfy
//
//  Created by Claude on 24/12/25.
//

import Foundation

/// Configuration for a single managed topic from MDM
struct ManagedTopicConfig {
    let name: String
    let serverURL: String?
    let username: String?

    init(name: String, serverURL: String? = nil, username: String? = nil) {
        self.name = name
        self.serverURL = serverURL
        self.username = username
    }

    /// Initialize from a dictionary (from MDM configuration)
    init?(from dict: [String: Any]) {
        guard let name = dict["name"] as? String else { return nil }
        self.name = name
        self.serverURL = dict["serverURL"] as? String
        self.username = dict["username"] as? String
    }
}

/// MDM configuration for the ntfy app
struct ManagedConfiguration {
    /// Pre-configured topics that cannot be deleted by users
    let topics: [ManagedTopicConfig]?

    /// Force launch at login to be enabled
    let launchAtLogin: Bool?

    init(topics: [ManagedTopicConfig]?, launchAtLogin: Bool?) {
        self.topics = topics
        self.launchAtLogin = launchAtLogin
    }

    /// Default configuration when no MDM config is present
    static let defaultConfiguration = ManagedConfiguration(topics: nil, launchAtLogin: nil)

    /// Initialize from a dictionary (from MDM configuration)
    init(from dict: [String: Any]) {
        // Parse topics array
        if let topicsArray = dict["topics"] as? [[String: Any]] {
            self.topics = topicsArray.compactMap { ManagedTopicConfig(from: $0) }
        } else {
            self.topics = nil
        }

        // Parse launch at login
        self.launchAtLogin = dict["launchAtLogin"] as? Bool
    }
}
