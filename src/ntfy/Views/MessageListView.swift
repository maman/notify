//
//  MessageListView.swift
//  ntfy
//
//  Created by Achmad Mahardi on 19/12/25.
//

import SwiftUI
import SwiftData

struct MessageListView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    let topic: Topic

    // Memoized sorted messages - only re-sort when message count changes
    @State private var sortedMessages: [Message] = []

    var body: some View {
        Group {
            if sortedMessages.isEmpty {
                ContentUnavailableView(
                    "No Messages",
                    systemImage: "tray",
                    description: Text(String(format: String(localized: "Messages for '%@' will appear here"), topic.effectiveDisplayName))
                )
                .accessibilityIdentifier("emptyMessagesView")
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(sortedMessages) { message in
                            MessageRowView(
                                message: message,
                                highlightedId: appState.highlightedMessageId,
                                onMarkAsRead: {
                                    appState.markAsRead(message, modelContext: modelContext)
                                },
                                onDelete: {
                                    appState.deleteMessage(message, modelContext: modelContext)
                                },
                                onClearHighlight: {
                                    appState.highlightedMessageId = nil
                                }
                            )
                        }
                    }
                    .padding()
                }
                .accessibilityIdentifier("messagesList")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle(topic.effectiveDisplayName)
        .onAppear {
            updateSortedMessages()
        }
        .onChange(of: topic.id) { _, _ in
            // Update when switching to a different topic
            updateSortedMessages()
        }
        .onChange(of: topic.messages.count) { _, _ in
            // Update when messages are added/removed
            updateSortedMessages()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        appState.markAllAsRead(for: topic, modelContext: modelContext)
                    } label: {
                        Label("Mark All as Read", systemImage: "checkmark.circle")
                    }
                    .disabled(topic.unreadCount == 0)
                    .accessibilityIdentifier("markAllReadButton")

                    Divider()

                    Button(role: .destructive) {
                        clearAllMessages()
                    } label: {
                        Label("Clear All Messages", systemImage: "trash")
                    }
                    .disabled(sortedMessages.isEmpty)
                    .accessibilityIdentifier("clearAllButton")
                } label: {
                    Label("Actions", systemImage: "ellipsis.circle")
                }
                .accessibilityIdentifier("actionsMenu")
            }
        }
    }

    private func updateSortedMessages() {
        sortedMessages = topic.messages.sorted { $0.receivedAt > $1.receivedAt }
    }

    private func clearAllMessages() {
        for message in topic.messages {
            modelContext.delete(message)
        }
        try? modelContext.save()
        updateSortedMessages()
    }
}

#Preview {
    let topic = Topic(name: "test-topic")
    return MessageListView(topic: topic)
        .environment(AppState())
        .modelContainer(for: [Topic.self, Message.self], inMemory: true)
}
