//
//  MessageRowView.swift
//  ntfy
//
//  Created by Achmad Mahardi on 19/12/25.
//

import SwiftUI
import SwiftData

// Static color constants to avoid creating new Color objects on each render
private enum RowColors {
    static let flashing = Color.accentColor.opacity(0.3)
    static let hovered = Color.secondary.opacity(0.05)
    static let unread = Color.secondary.opacity(0.1)
    static let normal = Color.clear
}

struct MessageRowView: View {
    @Environment(\.openURL) private var openURL

    let message: Message
    let highlightedId: String?
    let onMarkAsRead: () -> Void
    let onDelete: () -> Void
    let onClearHighlight: () -> Void

    @State private var isHovered = false
    @State private var isFlashing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                // Priority icon
                Image(systemName: message.priorityIcon)
                    .foregroundStyle(priorityColor)
                    .font(.caption)

                // Title
                Text(message.displayTitle)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                // Actions
                HStack(spacing: 4) {
                    // Mark as read
                    Button {
                        onMarkAsRead()
                    } label: {
                        Image(systemName: message.isRead ? "checkmark.circle.fill" : "checkmark.circle")
                            .foregroundStyle(message.isRead ? .green : .secondary)
                    }
                    .buttonStyle(.plain)
                    .controlSize(.small)
                    .help(message.isRead ? "Already read" : "Mark as read")
                    .accessibilityIdentifier("markReadButton-\(message.id)")

                    // Delete
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                    .controlSize(.small)
                    .help("Delete message")
                    .accessibilityIdentifier("deleteButton-\(message.id)")
                }
            }

            // Body
            Text(message.body)
                .font(.body)
                .foregroundStyle(message.isRead ? .secondary : .primary)
                .lineLimit(3)

            // Tags
            if let tags = message.tags, !tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(tags, id: \.self) { tag in
                        TagView(tag: tag)
                    }
                }
            }

            // Action buttons
            if let actions = message.actions, !actions.isEmpty {
                HStack(spacing: 8) {
                    ForEach(actions) { action in
                        Button {
                            performAction(action)
                        } label: {
                            Text(action.label)
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }

            // Timestamp
            HStack {
                Spacer()
                Text(message.receivedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(flashBackgroundColor)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        }
        .animation(.easeInOut(duration: 0.3), value: isFlashing)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture {
            // Mark as read on tap
            if !message.isRead {
                onMarkAsRead()
            }

            // Open click URL if available
            if let click = message.click, let url = URL(string: click) {
                openURL(url)
            }
        }
        .onAppear {
            // Check if this message should flash on appear (from notification click)
            if highlightedId == message.id {
                triggerFlash()
            }
        }
        .onChange(of: highlightedId) { _, newId in
            // Flash animation when this message is highlighted from notification click
            if newId == message.id {
                triggerFlash()
            }
        }
        .accessibilityLabel(accessibilityDescription)
        .accessibilityValue(Text(message.isRead ? "Read" : "Unread"))
        .accessibilityIdentifier("messageRow-\(message.id)")
    }

    private func triggerFlash() {
        isFlashing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isFlashing = false
            onClearHighlight()
        }
    }

    private var flashBackgroundColor: Color {
        // Use static color constants to avoid allocations
        if isFlashing {
            return RowColors.flashing
        } else if isHovered {
            return RowColors.hovered
        } else if !message.isRead {
            return RowColors.unread
        } else {
            return RowColors.normal
        }
    }

    private var accessibilityDescription: String {
        var description = message.displayTitle
        description += ". \(message.body)"

        let priorityText: String
        switch message.priority {
        case 5:
            priorityText = String(localized: "High priority")
        case 4:
            priorityText = String(localized: "Medium-high priority")
        case 2:
            priorityText = String(localized: "Low priority")
        case 1:
            priorityText = String(localized: "Very low priority")
        default:
            priorityText = String(localized: "Normal priority")
        }
        description += ". \(priorityText)"

        return description
    }

    private var priorityColor: Color {
        switch message.priority {
        case 5: return .red
        case 4: return .orange
        case 2: return .blue
        case 1: return .gray
        default: return .secondary
        }
    }

    private func performAction(_ action: MessageAction) {
        switch action.action {
        case "view":
            if let urlString = action.url, let url = URL(string: urlString) {
                openURL(url)
            }
        case "http":
            // Perform HTTP request
            Task {
                await performHTTPAction(action)
            }
        default:
            break
        }
    }

    private func performHTTPAction(_ action: MessageAction) async {
        guard let urlString = action.url, let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = action.method ?? "POST"

        if let headers = action.headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }

        if let body = action.body {
            request.httpBody = body.data(using: .utf8)
        }

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP action completed with status: \(httpResponse.statusCode)")
            }
        } catch {
            print("HTTP action failed: \(error)")
        }
    }
}

struct TagView: View {
    let tag: String

    var body: some View {
        // Check if tag is an emoji (ntfy supports emoji tags)
        if let emoji = emojiForTag(tag) {
            Text(emoji)
                .font(.caption)
        } else {
            Text(tag)
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.secondary.opacity(0.2)))
        }
    }

    private func emojiForTag(_ tag: String) -> String? {
        // Common ntfy tag to emoji mappings
        let emojiMap: [String: String] = [
            "warning": "⚠️",
            "skull": "💀",
            "rotating_light": "🚨",
            "tada": "🎉",
            "white_check_mark": "✅",
            "x": "❌",
            "no_entry": "⛔",
            "loudspeaker": "📢",
            "mega": "📣",
            "bell": "🔔",
            "fire": "🔥",
            "eyes": "👀",
            "rocket": "🚀",
            "star": "⭐",
            "heart": "❤️",
            "thumbsup": "👍",
            "thumbsdown": "👎",
            "cd": "💿",
            "computer": "💻",
            "package": "📦"
        ]
        return emojiMap[tag]
    }
}

#Preview {
    let topic = Topic(name: "test")
    let message = Message(
        id: "test-1",
        topic: topic,
        title: "Test Message",
        body: "This is a test message body that might be quite long and span multiple lines to demonstrate the truncation behavior.",
        priority: 4,
        tags: ["warning", "test"],
        actions: [
            MessageAction(action: "view", label: "Open URL", url: "https://example.com")
        ]
    )

    return ScrollView {
        MessageRowView(
            message: message,
            highlightedId: nil,
            onMarkAsRead: {},
            onDelete: {},
            onClearHighlight: {}
        )
        .padding()
    }
    .modelContainer(for: [Topic.self, Message.self], inMemory: true)
}
