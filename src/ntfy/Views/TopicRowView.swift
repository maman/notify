//
//  TopicRowView.swift
//  ntfy
//
//  Created by Achmad Mahardi on 19/12/25.
//

import SwiftUI
import SwiftData

struct TopicRowView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    let topic: Topic
    let allTopics: [Topic]  // Passed from parent to avoid duplicate @Query

    @State private var newDisplayName = ""
    @State private var showRenameSheet = false
    @State private var activeAlert: AlertType?

    enum AlertType: Identifiable {
        case deleteSingle
        case deleteBulk

        var id: Self { self }
    }

    /// Whether this topic is part of a multi-selection
    private var isInMultiSelection: Bool {
        appState.selectedTopicIds.count > 1 && appState.selectedTopicIds.contains(topic.id)
    }

    /// Topics currently selected (for bulk operations)
    private var selectedTopics: [Topic] {
        allTopics.filter { appState.selectedTopicIds.contains($0.id) }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(topic.effectiveDisplayName)
                    .font(.headline)

                HStack(spacing: 4) {
                    Text(topic.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if topic.serverURL != "https://ntfy.sh" {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(serverDisplayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if topic.username != nil {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Connection status indicator
            Circle()
                .fill(connectionColor)
                .frame(width: 8, height: 8)
                .accessibilityIdentifier("connectionIndicator-\(topic.id.uuidString)")

            // Unread count badge
            if topic.unreadCount > 0 {
                Text("\(topic.unreadCount)")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(.red))
                    .accessibilityIdentifier("unreadBadge-\(topic.id.uuidString)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .accessibilityIdentifier("topicRow-\(topic.id.uuidString)")
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                newDisplayName = topic.displayName ?? ""
                showRenameSheet = true
            } label: {
                Image(systemName: "pencil")
            }
            .tint(.blue)

            Button(role: .destructive) {
                activeAlert = .deleteSingle
            } label: {
                Image(systemName: "bell.slash")
            }
        }
        .contextMenu {
            if isInMultiSelection {
                // Bulk actions when multiple topics are selected
                Button(role: .destructive) {
                    activeAlert = .deleteBulk
                } label: {
                    Label("Unsubscribe from \(appState.selectedTopicIds.count) Topics...", systemImage: "bell.slash")
                }
            } else {
                // Single topic actions
                Button {
                    newDisplayName = topic.displayName ?? ""
                    showRenameSheet = true
                } label: {
                    Label("Rename...", systemImage: "pencil")
                }

                Divider()

                Button(role: .destructive) {
                    activeAlert = .deleteSingle
                } label: {
                    Label("Unsubscribe", systemImage: "bell.slash")
                }
            }
        }
        .alert(item: $activeAlert) { alertType in
            switch alertType {
            case .deleteSingle:
                Alert(
                    title: Text("Confirm Unsubscribe"),
                    message: Text(String(format: String(localized: "Are you sure you want to unsubscribe from '%@'? All message history will be permanently deleted."), topic.effectiveDisplayName)),
                    primaryButton: .destructive(Text("Unsubscribe")) {
                        Task {
                            await appState.deleteTopic(topic, modelContext: modelContext)
                        }
                    },
                    secondaryButton: .cancel()
                )
            case .deleteBulk:
                Alert(
                    title: Text("Confirm Unsubscribe"),
                    message: Text("Are you sure you want to unsubscribe from \(appState.selectedTopicIds.count) topics? All message history will be permanently deleted."),
                    primaryButton: .destructive(Text("Unsubscribe")) {
                        Task {
                            await appState.deleteTopics(selectedTopics, modelContext: modelContext)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        .sheet(isPresented: $showRenameSheet) {
            RenameTopicSheet(topic: topic, initialName: newDisplayName)
        }
    }

    private var serverDisplayName: String {
        URL(string: topic.serverURL)?.host ?? topic.serverURL
    }

    private var connectionColor: Color {
        // Use per-topic observable - only this row re-renders when its state changes
        let state = appState.ntfyService.connectionState(for: topic.id).state

        switch state {
        case .connected:
            return .green
        case .connecting, .reconnecting:
            return .yellow
        case .disconnected:
            return .gray
        case .failed:
            return .red
        }
    }
}

/// Sheet for renaming a topic with TextField
private struct RenameTopicSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let topic: Topic
    @State var initialName: String

    var body: some View {
        VStack(spacing: 16) {
            Text("Alias Name")
                .font(.headline)

            TextField("Display Name", text: $initialName)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Rename") {
                    appState.renameTopic(topic, to: initialName, modelContext: modelContext)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 300)
    }
}

#Preview {
    let topic = Topic(name: "test-topic", serverURL: "https://ntfy.sh")
    return List {
        TopicRowView(topic: topic, allTopics: [topic])
    }
    .environment(AppState())
    .modelContainer(for: [Topic.self, Message.self], inMemory: true)
}
