//
//  NtfyFocusFilter.swift
//  ntfy
//
//  Created by Claude on 24/12/24.
//

import AppIntents

/// Focus Filter for filtering ntfy notifications during Focus modes
struct NtfyFocusFilter: SetFocusFilterIntent {
    static var title: LocalizedStringResource = "Set Notify Filter"
    static var description: IntentDescription? = IntentDescription("Filter notifications based on topics and priority during Focus")

    @Parameter(title: "Allow All Topics", default: true)
    var allowAllTopics: Bool

    @Parameter(title: "Allowed Topics", default: [])
    var allowedTopics: [TopicEntity]

    @Parameter(title: "Minimum Priority", default: .normal)
    var minimumPriority: MessagePriority

    var displayRepresentation: DisplayRepresentation {
        if allowAllTopics {
            return DisplayRepresentation(
                title: "All topics",
                subtitle: "Priority \(minimumPriority.localizedName) and above"
            )
        } else if allowedTopics.isEmpty {
            return DisplayRepresentation(
                title: "Block all notifications",
                subtitle: "No topics allowed"
            )
        } else {
            let topicNames = allowedTopics.prefix(3).map(\.displayName).joined(separator: ", ")
            let suffix = allowedTopics.count > 3 ? " +\(allowedTopics.count - 3) more" : ""
            return DisplayRepresentation(
                title: LocalizedStringResource(stringLiteral: topicNames + suffix),
                subtitle: "Priority \(minimumPriority.localizedName)+"
            )
        }
    }

    /// Provides the notification filter predicate for Focus mode
    var appContext: FocusFilterAppContext {
        // If blocking all, return a predicate that matches nothing
        if !allowAllTopics && allowedTopics.isEmpty {
            return FocusFilterAppContext(notificationFilterPredicate: NSPredicate(value: false))
        }

        let minPriority = minimumPriority.rawValue

        // filterCriteria format: "topic:<uuid>:priority:<N>"
        // We need to match notifications where priority >= minPriority

        if allowAllTopics {
            // Match any topic with priority >= minimum
            // Pattern: any text ending with :priority:N where N >= minPriority
            let priorityPattern = priorityMatchPattern(minPriority: minPriority)
            return FocusFilterAppContext(
                notificationFilterPredicate: NSPredicate(format: "SELF MATCHES %@", ".*:\(priorityPattern)")
            )
        } else {
            // Match specific topics with priority >= minimum
            let topicPatterns = allowedTopics.map { "topic:\($0.id.uuidString)" }
            let topicGroup = "(" + topicPatterns.joined(separator: "|") + ")"
            let priorityPattern = priorityMatchPattern(minPriority: minPriority)
            let fullPattern = "\(topicGroup):\(priorityPattern)"

            return FocusFilterAppContext(
                notificationFilterPredicate: NSPredicate(format: "SELF MATCHES %@", fullPattern)
            )
        }
    }

    /// Creates a regex pattern that matches priority:N where N >= minPriority
    private func priorityMatchPattern(minPriority: Int) -> String {
        // Build character class for valid priorities
        let validPriorities = (minPriority...5).map { String($0) }.joined()
        return "priority:[\(validPriorities)]"
    }

    func perform() async throws -> some IntentResult {
        // Save filter configuration to shared UserDefaults for app to read
        let defaults = await UserDefaults(suiteName: BuildConfiguration.current.appGroup)
        defaults?.set(allowAllTopics, forKey: "focus.allowAllTopics")
        defaults?.set(minimumPriority.rawValue, forKey: "focus.minimumPriority")
        defaults?.set(allowedTopics.map(\.id.uuidString), forKey: "focus.allowedTopicIds")

        return .result()
    }
}

// MARK: - Suggested Filters

extension NtfyFocusFilter {
    static func suggestedFocusFilters(for context: FocusFilterSuggestionContext) async -> [NtfyFocusFilter] {
        // Create filter suggestions using default values
        // Note: SetFocusFilterIntent uses default parameter values, we create instances
        // that will be configured by the system

        return [
            NtfyFocusFilter(), // Default: All topics, normal priority
            NtfyFocusFilter(), // User can customize
            NtfyFocusFilter()  // User can customize
        ]
    }
}

// MARK: - Helper

extension MessagePriority {
    var localizedName: String {
        switch self {
        case .min: return "Minimum"
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High"
        case .urgent: return "Urgent"
        }
    }
}
