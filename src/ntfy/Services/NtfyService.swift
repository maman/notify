//
//  NtfyService.swift
//  ntfy
//
//  Created by Achmad Mahardi on 19/12/25.
//

import Foundation
import AppKit

// MARK: - Connection State

enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case reconnecting(attempt: Int)
    case failed
}

// MARK: - Per-Topic Connection State Observable
// Each topic gets its own observable to prevent dictionary mutation from invalidating all views

@Observable
final class TopicConnectionState {
    var state: ConnectionState = .disconnected
}

// MARK: - Pure Actor for SSE (Server-Sent Events) Logic

actor NtfyServiceActor {
    private static let maxReconnectAttempts = 10

    private var streamTasks: [UUID: Task<Void, Never>] = [:]
    private var reconnectTasks: [UUID: Task<Void, Never>] = [:]
    private var reconnectAttempts: [UUID: Int] = [:]
    private var connectionStates: [UUID: ConnectionState] = [:]

    var onMessageReceived: ((NtfyMessage, UUID) -> Void)?
    var onConnectionStateChanged: ((UUID, ConnectionState) -> Void)?

    // MARK: - Public API

    func subscribe(to topic: Topic) async {
        guard let url = topic.sseURL else { return }

        // Cancel existing connection if any
        unsubscribe(from: topic)

        setConnectionState(topic.id, .connecting)

        var request = URLRequest(url: url)

        // Add auth header if credentials exist
        if let username = topic.username {
            let authHeader = await KeychainService.shared.basicAuthHeader(username: username, topicId: topic.id)
            if let authHeader = authHeader {
                request.setValue(authHeader, forHTTPHeaderField: "Authorization")
            }
        }

        // Create SSE streaming task
        let streamTask = Task { [weak self] in
            guard let self = self else { return }

            do {
                let (bytes, response) = try await URLSession.shared.bytes(for: request)

                // Check HTTP response
                guard let httpResponse = response as? HTTPURLResponse else {
                    await self.setConnectionState(topic.id, .disconnected)
                    await self.scheduleReconnect(for: topic)
                    return
                }

                if httpResponse.statusCode != 200 {
                    print("SSE connection failed with status: \(httpResponse.statusCode)")
                    await self.setConnectionState(topic.id, .disconnected)
                    await self.scheduleReconnect(for: topic)
                    return
                }

                // Successfully connected
                await self.setConnectionState(topic.id, .connected)
                await self.resetReconnectAttempts(for: topic.id)

                // Read SSE lines
                for try await line in bytes.lines {
                    // Skip empty lines and keepalive comments
                    if line.isEmpty || line.hasPrefix(":") {
                        continue
                    }

                    // Parse SSE data lines
                    if line.hasPrefix("data: ") {
                        let json = String(line.dropFirst(6))
                        if let data = json.data(using: .utf8) {
                            await self.handleDataMessage(data, for: topic)
                        }
                    }
                }

                // Stream ended (server closed connection)
                await self.setConnectionState(topic.id, .disconnected)
                await self.scheduleReconnect(for: topic)

            } catch is CancellationError {
                // Task was cancelled, clean exit
                await self.setConnectionState(topic.id, .disconnected)
            } catch let urlError as URLError where urlError.code == .cancelled {
                // URLSession task was cancelled (e.g., during unsubscribe), clean exit
                await self.setConnectionState(topic.id, .disconnected)
            } catch {
                // Connection error, attempt reconnection
                print("SSE connection error: \(error)")
                await self.setConnectionState(topic.id, .disconnected)
                await self.scheduleReconnect(for: topic)
            }
        }

        streamTasks[topic.id] = streamTask
    }

    func unsubscribe(from topic: Topic) {
        reconnectTasks[topic.id]?.cancel()
        reconnectTasks.removeValue(forKey: topic.id)

        streamTasks[topic.id]?.cancel()
        streamTasks.removeValue(forKey: topic.id)

        connectionStates.removeValue(forKey: topic.id)
        reconnectAttempts.removeValue(forKey: topic.id)
    }

    func disconnectAll() {
        for (id, _) in streamTasks {
            reconnectTasks[id]?.cancel()
            streamTasks[id]?.cancel()
        }
        streamTasks.removeAll()
        reconnectTasks.removeAll()
        connectionStates.removeAll()
        reconnectAttempts.removeAll()
    }

    func getConnectionState(for topicID: UUID) -> ConnectionState {
        connectionStates[topicID] ?? .disconnected
    }

    /// Reconnects all topics - useful after sleep/wake
    func reconnectAll(topics: [Topic]) async {
        // Reset all attempt counters for fresh reconnection
        for topic in topics {
            reconnectAttempts[topic.id] = 0
        }
        // Resubscribe to all topics
        for topic in topics {
            await subscribe(to: topic)
        }
    }

    // MARK: - Private Helpers

    private func setConnectionState(_ topicID: UUID, _ state: ConnectionState) {
        connectionStates[topicID] = state
        onConnectionStateChanged?(topicID, state)
    }

    private func resetReconnectAttempts(for topicID: UUID) {
        reconnectAttempts[topicID] = 0
    }

    /// Decode NtfyMessage outside actor isolation to avoid Decodable conformance warnings
    private nonisolated func decodeNtfyMessage(from data: Data) throws -> NtfyMessage {
        try JSONDecoder().decode(NtfyMessage.self, from: data)
    }

    private func handleDataMessage(_ data: Data, for topic: Topic) {
        do {
            let ntfyMessage = try decodeNtfyMessage(from: data)

            // Only process actual messages, not keepalives or open events
            guard ntfyMessage.event == .message else { return }

            // Capture callback and topic ID (Sendable) to avoid actor isolation issues
            let callback = onMessageReceived
            let topicID = topic.id
            Task { @MainActor in
                callback?(ntfyMessage, topicID)
            }
        } catch {
            print("Failed to decode message: \(error)")
        }
    }

    private func scheduleReconnect(for topic: Topic) {
        // Get current attempt count
        let currentAttempt = reconnectAttempts[topic.id] ?? 0
        let nextAttempt = currentAttempt + 1

        // Check if max attempts reached
        if nextAttempt > Self.maxReconnectAttempts {
            setConnectionState(topic.id, .failed)
            print("Max reconnect attempts (\(Self.maxReconnectAttempts)) reached for topic: \(topic.name)")
            return
        }

        // Update attempt count
        reconnectAttempts[topic.id] = nextAttempt

        // Exponential backoff: 5s, 10s, 20s, 40s, max 60s
        let delay = min(5.0 * pow(2.0, Double(nextAttempt - 1)), 60.0)

        setConnectionState(topic.id, .reconnecting(attempt: nextAttempt))

        let reconnectTask = Task {
            try? await Task.sleep(for: .seconds(delay))

            guard !Task.isCancelled else { return }

            await subscribe(to: topic)
        }

        reconnectTasks[topic.id] = reconnectTask
    }
}

// MARK: - Observable Wrapper for UI Binding

@Observable
final class NtfyService {
    let actor = NtfyServiceActor()

    /// Per-topic connection state observables - each topic row observes only its own state
    private var connectionStateObjects: [UUID: TopicConnectionState] = [:]

    /// Topics to reconnect on wake - set by the view that manages subscriptions
    var topicsToReconnect: [Topic] = []

    /// Observer tokens for NotificationCenter cleanup
    private var sleepObserver: Any?
    private var wakeObserver: Any?

    init() {
        Task {
            await actor.setOnConnectionStateChanged { [weak self] topicID, state in
                Task { @MainActor in
                    // Update the per-topic observable instead of dictionary
                    self?.connectionState(for: topicID).state = state
                }
            }
        }

        // Listen for system wake notifications
        setupWakeNotification()
    }

    /// Get or create a connection state observable for a specific topic
    /// Each view can observe only its topic's state, preventing cascading re-renders
    func connectionState(for topicId: UUID) -> TopicConnectionState {
        if let existing = connectionStateObjects[topicId] {
            return existing
        }
        let newState = TopicConnectionState()
        connectionStateObjects[topicId] = newState
        return newState
    }

    private func setupWakeNotification() {
        // Disconnect gracefully before sleep
        sleepObserver = NotificationCenter.default.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("System going to sleep - disconnecting all topics")
            self?.disconnectAll()
        }

        // Reconnect after wake
        wakeObserver = NotificationCenter.default.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            print("System woke from sleep - reconnecting all topics")
            Task {
                await self.reconnectAllTopics()
            }
        }
    }

    deinit {
        if let sleepObserver = sleepObserver {
            NotificationCenter.default.removeObserver(sleepObserver)
        }
        if let wakeObserver = wakeObserver {
            NotificationCenter.default.removeObserver(wakeObserver)
        }
    }

    /// Reconnects all tracked topics after sleep/wake
    func reconnectAllTopics() async {
        guard !topicsToReconnect.isEmpty else { return }
        await actor.reconnectAll(topics: topicsToReconnect)
        for topic in topicsToReconnect {
            await syncState(for: topic.id)
        }
    }

    func subscribe(to topic: Topic) async {
        await actor.subscribe(to: topic)
        await syncState(for: topic.id)
    }

    func unsubscribe(from topic: Topic) async {
        await actor.unsubscribe(from: topic)
        connectionStateObjects.removeValue(forKey: topic.id)
    }

    func disconnectAll() {
        Task {
            await actor.disconnectAll()
            // Reset all connection states to disconnected
            for (_, stateObject) in connectionStateObjects {
                stateObject.state = .disconnected
            }
        }
    }

    func isConnected(to topic: Topic) -> Bool {
        connectionState(for: topic.id).state == .connected
    }

    private func syncState(for topicID: UUID) async {
        let state = await actor.getConnectionState(for: topicID)
        await MainActor.run {
            connectionState(for: topicID).state = state
        }
    }
}

// MARK: - Actor Extensions for Property Setting

extension NtfyServiceActor {
    func setOnMessageReceived(_ handler: ((NtfyMessage, UUID) -> Void)?) {
        onMessageReceived = handler
    }

    func setOnConnectionStateChanged(_ handler: ((UUID, ConnectionState) -> Void)?) {
        onConnectionStateChanged = handler
    }
}
