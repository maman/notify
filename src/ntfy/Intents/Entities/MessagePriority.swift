//
//  MessagePriority.swift
//  ntfy
//
//  Created by Claude on 24/12/24.
//

import AppIntents

/// App Enum for message priority levels used in App Intents and Focus Filters
enum MessagePriority: Int, AppEnum, CaseIterable, Sendable {
    case min = 1
    case low = 2
    case normal = 3
    case high = 4
    case urgent = 5

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Priority")
    }

    static var caseDisplayRepresentations: [MessagePriority: DisplayRepresentation] {
        [
            .min: DisplayRepresentation(
                title: "Minimum",
                subtitle: "Lowest priority",
                image: .init(systemName: "minus.circle")
            ),
            .low: DisplayRepresentation(
                title: "Low",
                subtitle: "Below normal priority",
                image: .init(systemName: "arrow.down.circle")
            ),
            .normal: DisplayRepresentation(
                title: "Normal",
                subtitle: "Default priority",
                image: .init(systemName: "bell")
            ),
            .high: DisplayRepresentation(
                title: "High",
                subtitle: "Above normal priority",
                image: .init(systemName: "exclamationmark.circle.fill")
            ),
            .urgent: DisplayRepresentation(
                title: "Urgent",
                subtitle: "Highest priority - critical",
                image: .init(systemName: "exclamationmark.triangle.fill")
            )
        ]
    }
}
