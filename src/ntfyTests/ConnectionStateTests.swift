//
//  ConnectionStateTests.swift
//  ntfyTests
//
//  Created by Achmad Mahardi on 20/12/25.
//

import Testing
@testable import Notify

@Suite("Connection State")
struct ConnectionStateTests {

    // MARK: - Equatable Tests

    @Test("Disconnected states are equal")
    func equatable_disconnectedEqual() {
        let state1 = ConnectionState.disconnected
        let state2 = ConnectionState.disconnected
        #expect(state1 == state2)
    }

    @Test("Connecting states are equal")
    func equatable_connectingEqual() {
        let state1 = ConnectionState.connecting
        let state2 = ConnectionState.connecting
        #expect(state1 == state2)
    }

    @Test("Connected states are equal")
    func equatable_connectedEqual() {
        let state1 = ConnectionState.connected
        let state2 = ConnectionState.connected
        #expect(state1 == state2)
    }

    @Test("Failed states are equal")
    func equatable_failedEqual() {
        let state1 = ConnectionState.failed
        let state2 = ConnectionState.failed
        #expect(state1 == state2)
    }

    @Test("Reconnecting states with same attempt are equal")
    func equatable_reconnectingSameAttemptEqual() {
        let state1 = ConnectionState.reconnecting(attempt: 3)
        let state2 = ConnectionState.reconnecting(attempt: 3)
        #expect(state1 == state2)
    }

    @Test("Reconnecting states with different attempts are not equal")
    func equatable_reconnectingDifferentAttemptNotEqual() {
        let state1 = ConnectionState.reconnecting(attempt: 1)
        let state2 = ConnectionState.reconnecting(attempt: 2)
        #expect(state1 != state2)
    }

    @Test("Different states are not equal")
    func equatable_differentStatesNotEqual() {
        #expect(ConnectionState.disconnected != ConnectionState.connecting)
        #expect(ConnectionState.connecting != ConnectionState.connected)
        #expect(ConnectionState.connected != ConnectionState.failed)
        #expect(ConnectionState.failed != ConnectionState.reconnecting(attempt: 1))
        #expect(ConnectionState.reconnecting(attempt: 1) != ConnectionState.disconnected)
    }

    // MARK: - Reconnecting Attempt Tests

    @Test("Reconnecting includes attempt count")
    func reconnecting_includesAttemptCount() {
        let state = ConnectionState.reconnecting(attempt: 5)

        if case .reconnecting(let attempt) = state {
            #expect(attempt == 5)
        } else {
            Issue.record("Expected reconnecting state")
        }
    }

    @Test("Reconnecting attempt can be zero")
    func reconnecting_attemptCanBeZero() {
        let state = ConnectionState.reconnecting(attempt: 0)

        if case .reconnecting(let attempt) = state {
            #expect(attempt == 0)
        } else {
            Issue.record("Expected reconnecting state")
        }
    }

    @Test("Reconnecting attempt can be large number")
    func reconnecting_attemptCanBeLarge() {
        let state = ConnectionState.reconnecting(attempt: 100)

        if case .reconnecting(let attempt) = state {
            #expect(attempt == 100)
        } else {
            Issue.record("Expected reconnecting state")
        }
    }

    // MARK: - All States Distinct Tests

    @Test("All five state types are distinct")
    func allStates_areDistinct() {
        let states: [ConnectionState] = [
            .disconnected,
            .connecting,
            .connected,
            .reconnecting(attempt: 1),
            .failed
        ]

        // Check all pairs are different
        for i in 0..<states.count {
            for j in (i+1)..<states.count {
                #expect(states[i] != states[j], "States at index \(i) and \(j) should be different")
            }
        }
    }

    // MARK: - Pattern Matching Tests

    @Test("Pattern matching works for all states")
    func patternMatching_worksForAllStates() {
        func describedState(_ state: ConnectionState) -> String {
            switch state {
            case .disconnected: return "disconnected"
            case .connecting: return "connecting"
            case .connected: return "connected"
            case .reconnecting(let attempt): return "reconnecting-\(attempt)"
            case .failed: return "failed"
            }
        }

        #expect(describedState(.disconnected) == "disconnected")
        #expect(describedState(.connecting) == "connecting")
        #expect(describedState(.connected) == "connected")
        #expect(describedState(.reconnecting(attempt: 3)) == "reconnecting-3")
        #expect(describedState(.failed) == "failed")
    }
}
