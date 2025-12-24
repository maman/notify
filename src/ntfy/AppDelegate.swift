//
//  AppDelegate.swift
//  ntfy
//
//  Created by Claude on 24/12/25.
//

import AppKit
import SwiftUI

/// App delegate to handle URL scheme for menu bar apps
/// MenuBarExtra doesn't support .onOpenURL, so we use NSApplicationDelegate
class AppDelegate: NSObject, NSApplicationDelegate {

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            handleURL(url)
        }
    }

    private func handleURL(_ url: URL) {
        // Extract topic name from URL (host component)
        guard url.scheme == "ntfy",
              let topicName = url.host else { return }

        // Post notification for SwiftUI views to handle
        NotificationCenter.default.post(
            name: .openTopicFromURL,
            object: nil,
            userInfo: ["topicName": topicName]
        )
    }
}

extension Notification.Name {
    static let openTopicFromURL = Notification.Name("openTopicFromURL")
}
