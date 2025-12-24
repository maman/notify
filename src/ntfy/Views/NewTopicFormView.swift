//
//  NewTopicFormView.swift
//  ntfy
//
//  Created by Achmad Mahardi on 19/12/25.
//

import SwiftUI
import SwiftData

struct NewTopicFormView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @State private var topicName = ""
    @State private var useCustomServer = false
    @State private var serverURL = "https://ntfy.sh"
    @State private var useAuth = false
    @State private var username = ""
    @State private var password = ""
    @State private var isSubscribing = false

    var body: some View {
        @Bindable var appState = appState

        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Subscribe to Topic")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .accessibilityAddTraits(.isHeader)

                Text("Enter a topic name to receive notifications")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 8)

            // Topic Name
            VStack(alignment: .leading, spacing: 4) {
                Text("Topic Name")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    TextField("Enter topic name", text: $topicName)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityIdentifier("topicNameField")

                    Button {
                        topicName = AppState.randomTopicName()
                    } label: {
                        Text("Randomize")
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("randomizeButton")
                }
            }

            // Custom Server Toggle
            Toggle("Use custom server", isOn: $useCustomServer.animation())
                .toggleStyle(.switch)
                .accessibilityIdentifier("customServerToggle")
                .onChange(of: useCustomServer) { _, newValue in
                    if !newValue {
                        useAuth = false
                        username = ""
                        password = ""
                        serverURL = "https://ntfy.sh"
                    }
                }

            if useCustomServer {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Server URL")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    TextField("https://ntfy.example.com", text: $serverURL)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityIdentifier("serverURLField")
                }

                Toggle("Requires authentication", isOn: $useAuth.animation())
                    .toggleStyle(.switch)
                    .accessibilityIdentifier("authToggle")

                if useAuth {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Username")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        TextField("Username", text: $username)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityIdentifier("usernameField")
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Password")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        SecureField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityIdentifier("passwordField")
                    }
                }
            }

            // Actions
            HStack {
                Button("Cancel") {
                    resetForm()
                    appState.isShowingNewTopicForm = false
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.escape, modifiers: [])
                .accessibilityIdentifier("cancelButton")

                Spacer()

                Button {
                    Task {
                        await subscribe()
                    }
                } label: {
                    if isSubscribing {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("Subscribe")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValidForm || isSubscribing)
                .keyboardShortcut(.return, modifiers: [])
                .accessibilityIdentifier("subscribeButton")
            }
            .padding(.top, 8)
        }
        .padding(24)
        .frame(maxWidth: 450, alignment: .leading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.thinMaterial)
        .navigationTitle("")
        .onAppear {
            // Pre-fill topic name if set by URL handler
            if let pending = appState.pendingTopicName {
                topicName = pending
                appState.pendingTopicName = nil
            }
        }
    }

    private var isValidForm: Bool {
        !topicName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func subscribe() async {
        isSubscribing = true
        defer { isSubscribing = false }

        let effectiveServerURL = useCustomServer ? serverURL : "https://ntfy.sh"

        // Validate custom server URL
        if useCustomServer {
            guard let components = URLComponents(string: effectiveServerURL),
                  components.scheme == "https" || components.scheme == "http",
                  components.host != nil else {
                print("Invalid server URL: \(effectiveServerURL)")
                return
            }
        }

        let effectiveUsername = useAuth ? username : nil
        let effectivePassword = useAuth ? password : nil

        let topic = await appState.addTopic(
            name: topicName.trimmingCharacters(in: .whitespacesAndNewlines),
            serverURL: effectiveServerURL,
            username: effectiveUsername,
            password: effectivePassword,
            modelContext: modelContext
        )

        // Select the new topic by ID
        appState.selectedTopicId = topic.id
        appState.isShowingNewTopicForm = false

        resetForm()
    }

    private func resetForm() {
        topicName = ""
        useCustomServer = false
        serverURL = "https://ntfy.sh"
        useAuth = false
        username = ""
        password = ""
    }
}

#Preview {
    NewTopicFormView()
        .environment(AppState())
        .modelContainer(for: [Topic.self, Message.self], inMemory: true)
        .frame(width: 500, height: 400)
}
