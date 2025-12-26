//
//  ntfyApp.swift
//  ntfy
//
//  Created by Achmad Mahardi on 19/12/25.
//

import SwiftUI
import SwiftData
import AppIntents

@main
struct ntfyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var appState = AppState()
    @Environment(\.openWindow) private var openWindow

    @MainActor
    init() {
        // Register App Intents dependencies
        AppDependencyManager.shared.add(dependency: IntentModelContextProvider.shared)
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Topic.self,
            Message.self,
        ])
        let config = BuildConfiguration.current
        let modelConfiguration = ModelConfiguration(
            config.swiftDataStoreName,
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        // Simple menu-style menubar
        MenuBarExtra {
            MenuBarContentView()
                .environment(appState)
                .modelContainer(sharedModelContainer)
        } label: {
            MenuBarBadgeLabel()
                .environment(appState)
                .modelContainer(sharedModelContainer)
        }
        .menuBarExtraStyle(.menu)

        // Separate window for topic management
        Window("Subscribed Topics", id: "topics") {
            SubscribedTopicsWindow()
                .environment(appState)
                .background(WindowAccessor(
                    onOpen: { appState.showInDock() },
                    onClose: { appState.hideFromDock() }
                ))
        }
        .modelContainer(sharedModelContainer)
        .defaultSize(width: 750, height: 550)
        .windowResizability(.contentSize)
        .commands {
            // Replace default About menu item
            CommandGroup(replacing: .appInfo) {
                Button("About Notify") {
                    openWindow(id: "about")
                    activateWindow(id: "about")
                }
            }
            // Add Check for Updates after About
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    appState.updaterService.checkForUpdates()
                }
                .disabled(!appState.updaterService.canCheckForUpdates)
            }
        }

        // About window
        Window("About Notify", id: "about") {
            AboutView()
                .environment(appState)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }

    private func activateWindow(id: String) {
        DispatchQueue.main.async {
            if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == id }) {
                window.makeKeyAndOrderFront(nil)
            }
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

/// Menu bar badge label that shows unread count and handles startup subscriptions
struct MenuBarBadgeLabel: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow
    @Query(sort: \Topic.createdAt) private var topics: [Topic]

    private var totalUnreadCount: Int {
        topics.reduce(0) { $0 + $1.unreadCount }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: totalUnreadCount > 0 ? BuildConfiguration.current.menubarIconWithNotification : BuildConfiguration.current.menubarIcon)
            if totalUnreadCount > 0 {
                Text("\(totalUnreadCount)")
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
        }
        .task {
            // Set model container for App Intents
            IntentModelContextProvider.shared.modelContainer = modelContext.container

            // Initialize managed topics from MDM configuration first
            await appState.initializeManagedTopics(modelContext: modelContext)

            // Subscribe to all topics on app startup
            // Label view is always rendered, so this runs immediately
            await subscribeToAllTopics()

            // Open topics window on first launch
            let launchKey = "\(BuildConfiguration.current.userDefaultsPrefix)hasLaunchedBefore"
            if !UserDefaults.standard.bool(forKey: launchKey) {
                UserDefaults.standard.set(true, forKey: launchKey)
                await MainActor.run {
                    openWindow(id: "topics")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "topics" }) {
                            window.makeKeyAndOrderFront(nil)
                        }
                        NSApp.activate(ignoringOtherApps: true)
                    }
                }
            }
        }
        .onChange(of: topics) { _, newTopics in
            // Keep topics list updated for sleep/wake reconnection
            appState.ntfyService.topicsToReconnect = newTopics

            // Subscribe to any new topics
            Task {
                for topic in newTopics {
                    // Check if not already connected using per-topic observable
                    if appState.ntfyService.connectionState(for: topic.id).state == .disconnected {
                        await appState.subscribe(to: topic)
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openTopic)) { notification in
            // Handle notification click - open topic window and select topic
            guard let topicIdString = notification.userInfo?["topicId"] as? String,
                  let topicId = UUID(uuidString: topicIdString) else { return }

            // Find and select the topic by ID
            if topics.contains(where: { $0.id == topicId }) {
                appState.selectedTopicId = topicId
                appState.isShowingNewTopicForm = false

                // Set message to highlight with flash animation
                if let messageId = notification.userInfo?["messageId"] as? String {
                    appState.highlightedMessageId = messageId
                }

                // Open the topics window and bring to front
                openWindow(id: "topics")
                DispatchQueue.main.async {
                    if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "topics" }) {
                        window.makeKeyAndOrderFront(nil)
                    }
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openTopicFromURL)) { notification in
            // Handle URL scheme - open topic or show subscribe form
            guard let topicName = notification.userInfo?["topicName"] as? String else { return }

            if let topic = topics.first(where: { $0.name == topicName }) {
                // Topic exists - select and open
                appState.selectedTopicId = topic.id
                appState.isShowingNewTopicForm = false
                openWindow(id: "topics")
                DispatchQueue.main.async {
                    if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "topics" }) {
                        window.makeKeyAndOrderFront(nil)
                    }
                    NSApp.activate(ignoringOtherApps: true)
                }
            } else {
                // Topic not subscribed - show new topic form pre-filled
                appState.pendingTopicName = topicName
                appState.isShowingNewTopicForm = true
                openWindow(id: "topics")
                DispatchQueue.main.async {
                    if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "topics" }) {
                        window.makeKeyAndOrderFront(nil)
                    }
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
        }
    }

    private func subscribeToAllTopics() async {
        // Set model container for notification actions (mark as read)
        await appState.notificationService.setModelContainer(modelContext.container)

        // Set up message handler to save to SwiftData
        await appState.ntfyService.actor.setOnMessageReceived { [modelContext] ntfyMessage, topicID in
            Task { @MainActor in
                // Look up Topic by ID
                let descriptor = FetchDescriptor<Topic>(predicate: #Predicate { $0.id == topicID })
                guard let topic = try? modelContext.fetch(descriptor).first else {
                    print("Failed to find topic with ID: \(topicID)")
                    return
                }

                let message = Message.from(ntfyMessage, topic: topic)
                modelContext.insert(message)
                do {
                    try modelContext.save()
                } catch {
                    print("Failed to save message: \(error)")
                }

                // Show notification
                await appState.notificationService.showNotification(for: ntfyMessage, topicID: topicID, topicDisplayName: topic.effectiveDisplayName)
            }
        }

        // Subscribe to all existing topics
        appState.ntfyService.topicsToReconnect = topics
        for topic in topics {
            await appState.subscribe(to: topic)
        }
        print("Subscribed to \(topics.count) topics on startup")
    }
}

/// Menu bar content with native macOS menu items
struct MenuBarContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        @Bindable var appState = appState

        Button("Show Topics") {
            openTopicsWindow()
        }
        .keyboardShortcut("t", modifiers: [.command])

        Divider()

        Button("Check for Updates...") {
            appState.updaterService.checkForUpdates()
        }
        .disabled(!appState.updaterService.canCheckForUpdates)

        Divider()

        // Show toggle or read-only state based on MDM management
        if appState.managedConfigService.isLaunchAtLoginManaged {
            // Read-only when managed by MDM
            HStack {
                Text("Run on Login")
                Spacer()
                Image(systemName: "building.2.fill")
                    .font(.caption)
                Text(appState.launchAtLogin ? "On" : "Off")
                    .foregroundStyle(.secondary)
            }
            .help("Controlled by your organization")
        } else {
            Toggle("Run on Login", isOn: $appState.launchAtLogin)
        }

        Divider()

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: [.command])
    }

    private func openTopicsWindow() {
        openWindow(id: "topics")
        // Delay activation to ensure window is created/shown first
        DispatchQueue.main.async {
            // Find and activate the topics window
            if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "topics" }) {
                window.makeKeyAndOrderFront(nil)
            }
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
	
