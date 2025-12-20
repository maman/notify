//
//  TopicListView.swift
//  ntfy
//
//  Created by Achmad Mahardi on 19/12/25.
//

import SwiftUI
import SwiftData

struct TopicListView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    let topics: [Topic]

    @State private var showBulkDeleteAlert = false
    @State private var showSingleDeleteAlert = false
    @State private var topicToDelete: Topic?

    var body: some View {
        @Bindable var appState = appState

        TopicListContent(
            topics: topics,
            appState: appState,
            showBulkDeleteAlert: $showBulkDeleteAlert,
            showSingleDeleteAlert: $showSingleDeleteAlert,
            topicToDelete: $topicToDelete
        )
        .alert("Confirm Unsubscribe", isPresented: $showBulkDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Unsubscribe", role: .destructive) {
                let topicsToDelete = topics.filter { appState.selectedTopicIds.contains($0.id) }
                Task {
                    await appState.deleteTopics(topicsToDelete, modelContext: modelContext)
                }
            }
        } message: {
            Text("Are you sure you want to unsubscribe from \(appState.selectedTopicIds.count) topics? All message history will be permanently deleted.")
        }
        .alert("Confirm Unsubscribe", isPresented: $showSingleDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Unsubscribe", role: .destructive) {
                if let topic = topicToDelete {
                    Task {
                        await appState.deleteTopic(topic, modelContext: modelContext)
                    }
                }
            }
        } message: {
            if let topic = topicToDelete {
                Text(String(format: String(localized: "Are you sure you want to unsubscribe from '%@'? All message history will be permanently deleted."), topic.effectiveDisplayName))
            }
        }
        .onChange(of: appState.selectedTopicIds) { oldIds, newIds in
            if oldIds.isEmpty && newIds.count == 1 {
                appState.isShowingNewTopicForm = false
            }
        }
        .onChange(of: topics) { _, newTopics in
            let validIds = Set(newTopics.map(\.id))
            let staleIds = appState.selectedTopicIds.subtracting(validIds)
            if !staleIds.isEmpty {
                appState.selectedTopicIds.subtract(staleIds)
            }
        }
    }
}

/// Extracted list content to help compiler with type-checking
private struct TopicListContent: View {
    let topics: [Topic]
    @Bindable var appState: AppState
    @Binding var showBulkDeleteAlert: Bool
    @Binding var showSingleDeleteAlert: Bool
    @Binding var topicToDelete: Topic?

    var body: some View {
        List(selection: $appState.selectedTopicIds) {
            if topics.isEmpty {
                ContentUnavailableView {
                    Label("No Topics", systemImage: "bell.slash")
                } description: {
                    Text("Subscribe to a topic to receive notifications")
                } actions: {
                    Button("Subscribe to Topic") {
                        appState.isShowingNewTopicForm = true
                    }
                    .accessibilityIdentifier("subscribeEmptyButton")
                }
                .accessibilityIdentifier("emptyTopicsView")
                .listRowBackground(Color.clear)
            } else {
                Section {
                    ForEach(topics) { topic in
                        TopicRowView(topic: topic, allTopics: topics)
                            .tag(topic.id)
                    }
                } header: {
                    Text("Subscribed Topics")
                }
            }
        }
        .listStyle(.sidebar)
        .background(.regularMaterial)
        .navigationTitle("Topics")
        .accessibilityIdentifier("topicsList")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    appState.selectedTopicIds.removeAll()
                    appState.isShowingNewTopicForm = true
                } label: {
                    Label("Subscribe to Topic", systemImage: "plus")
                }
                .accessibilityIdentifier("addTopicButton")
                .help("Subscribe to a new topic")
            }
        }
    }
}

#Preview {
    TopicListView(topics: [])
        .environment(AppState())
        .modelContainer(for: [Topic.self, Message.self], inMemory: true)
}
