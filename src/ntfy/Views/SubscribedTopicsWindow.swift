//
//  SubscribedTopicsWindow.swift
//  ntfy
//
//  Created by Achmad Mahardi on 19/12/25.
//

import SwiftUI
import SwiftData

struct SubscribedTopicsWindow: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Topic.createdAt, order: .reverse) private var topics: [Topic]

    @State private var showBulkDeleteAlert = false

    /// Look up selected topic by ID - only returns a topic when exactly one is selected
    private var selectedTopic: Topic? {
        guard appState.selectedTopicIds.count == 1,
              let selectedId = appState.selectedTopicIds.first else { return nil }
        return topics.first { $0.id == selectedId }
    }

    /// Number of currently selected topics
    private var selectedCount: Int {
        appState.selectedTopicIds.count
    }

    /// Topics currently selected (for bulk operations)
    private var selectedTopics: [Topic] {
        topics.filter { appState.selectedTopicIds.contains($0.id) }
    }

    var body: some View {
        @Bindable var appState = appState

        NavigationSplitView {
            TopicListView(topics: topics)
                .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
        } detail: {
            if appState.isShowingNewTopicForm {
                NewTopicFormView()
            } else if let selectedTopic = selectedTopic {
                MessageListView(topic: selectedTopic)
            } else if selectedCount > 1 {
                ContentUnavailableView {
                    Label("\(selectedCount) Topics Selected", systemImage: "checkmark.circle")
                } description: {
                    Text("Click below to unsubscribe from selected topics")
                } actions: {
                    Button(role: .destructive) {
                        showBulkDeleteAlert = true
                    } label: {
                        Text("Unsubscribe from \(selectedCount) Topics...")
                    }
                    .buttonStyle(.glass)
                    .glassEffect(.regular.tint(.red.opacity(0.3)))
                }
                .accessibilityIdentifier("multipleTopicsSelectedView")
            } else {
                ContentUnavailableView(
                    "No Topic Selected",
                    systemImage: "bell.slash",
                    description: Text("Select a topic from the sidebar to view messages")
                )
                .accessibilityIdentifier("noTopicSelectedView")
            }
        }
        .alert("Confirm Unsubscribe", isPresented: $showBulkDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Unsubscribe", role: .destructive) {
                Task {
                    await appState.deleteTopics(selectedTopics, modelContext: modelContext)
                }
            }
        } message: {
            Text("Are you sure you want to unsubscribe from \(selectedCount) topics? All message history will be permanently deleted.")
        }
        // Note: Subscription to topics is handled at app startup in MenuBarContentView
        // This window only handles UI for viewing/managing topics
    }
}

#Preview {
    SubscribedTopicsWindow()
        .environment(AppState())
        .modelContainer(for: [Topic.self, Message.self], inMemory: true)
}
