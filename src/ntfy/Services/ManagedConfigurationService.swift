//
//  ManagedConfigurationService.swift
//  ntfy
//
//  Created by Claude on 24/12/25.
//

import Foundation

/// Service that manages MDM configuration using UserDefaults
/// MDM servers deliver configuration via the "com.apple.configuration.managed" key
@Observable
final class ManagedConfigurationService {
    /// Key used by MDM to store managed app configuration
    private static let managedConfigKey = "com.apple.configuration.managed"

    /// Current managed configuration from MDM
    private(set) var configuration: ManagedConfiguration = .defaultConfiguration

    /// Observer for UserDefaults changes
    private var observer: NSObjectProtocol?

    // MARK: - Computed Properties

    /// Whether launch at login is managed by MDM
    var isLaunchAtLoginManaged: Bool {
        configuration.launchAtLogin != nil
    }

    /// The managed launch at login value (if set by MDM)
    var managedLaunchAtLogin: Bool? {
        configuration.launchAtLogin
    }

    /// Whether there are managed topics from MDM
    var hasManagedTopics: Bool {
        guard let topics = configuration.topics else { return false }
        return !topics.isEmpty
    }

    /// The list of managed topics (if any)
    var managedTopics: [ManagedTopicConfig] {
        configuration.topics ?? []
    }

    // MARK: - Initialization

    init() {
        loadConfiguration()
        startObservingConfiguration()
    }

    deinit {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Private Methods

    private func loadConfiguration() {
        if let dict = UserDefaults.standard.dictionary(forKey: Self.managedConfigKey) {
            configuration = ManagedConfiguration(from: dict)
        } else {
            configuration = .defaultConfiguration
        }
    }

    private func startObservingConfiguration() {
        // Observe UserDefaults changes for managed configuration updates
        observer = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.loadConfiguration()
        }
    }

    /// Force reload configuration (useful for testing)
    func reloadConfiguration() {
        loadConfiguration()
    }
}
