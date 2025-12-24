//
//  AboutView.swift
//  ntfy
//
//  About dialog with app info and update check
//

import SwiftUI

struct AboutView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    var body: some View {
        VStack(spacing: 16) {
            // App Icon
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)

            // App Name
            Text("Notify")
                .font(.title)
                .fontWeight(.semibold)

            // Version
            Text(String(format: String(localized: "Version %@ (%@)"), appVersion, buildNumber))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Description
            Text("A macOS menu bar app for ntfy.sh notifications")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
                .frame(height: 8)

            // Check for Updates button
            Button("Check for Updates...") {
                appState.updaterService.checkForUpdates()
            }
            .disabled(!appState.updaterService.canCheckForUpdates)

            Spacer()
                .frame(height: 8)

            // Copyright
            Text("\u{00A9} 2025 Achmad Mahardi")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(24)
        .frame(width: 280, height: 320)
    }
}

#Preview {
    AboutView()
        .environment(AppState())
}
