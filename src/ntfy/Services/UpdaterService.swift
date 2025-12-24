//
//  UpdaterService.swift
//  ntfy
//
//  Sparkle auto-update service
//

import Foundation
import Sparkle
import Combine

/// Observable wrapper for Sparkle updater to use with SwiftUI
@Observable
final class UpdaterService {
    private let updaterController: SPUStandardUpdaterController
    private var cancellables = Set<AnyCancellable>()

    /// Whether the user can currently check for updates
    var canCheckForUpdates: Bool = false

    init() {
        // Initialize updater controller - starts checking automatically on launch
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )

        // Observe canCheckForUpdates using Combine
        updaterController.updater.publisher(for: \.canCheckForUpdates)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.canCheckForUpdates = value
            }
            .store(in: &cancellables)
    }

    /// Manually trigger an update check (user-initiated)
    func checkForUpdates() {
        updaterController.updater.checkForUpdates()
    }
}
