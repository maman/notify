//
//  WindowAccessor.swift
//  ntfy
//
//  Created by Achmad Mahardi on 20/12/25.
//

import SwiftUI
import AppKit

/// A helper view that provides access to the underlying NSWindow for lifecycle events.
/// Uses NSWindow notifications for reliable open/close detection across SwiftUI window reuse.
struct WindowAccessor: NSViewRepresentable {
    var onOpen: (() -> Void)?
    var onClose: (() -> Void)?

    func makeNSView(context: Context) -> WindowObserverView {
        let view = WindowObserverView()
        view.onOpen = onOpen
        view.onClose = onClose
        return view
    }

    func updateNSView(_ nsView: WindowObserverView, context: Context) {
        nsView.onOpen = onOpen
        nsView.onClose = onClose
    }
}

/// Custom NSView that observes window lifecycle using multiple notification strategies
/// to handle SwiftUI's window reuse behavior.
class WindowObserverView: NSView {
    var onOpen: (() -> Void)?
    var onClose: (() -> Void)?

    private var becameKeyObserver: NSObjectProtocol?
    private var closeObserver: NSObjectProtocol?
    private var observedWindow: NSWindow?
    private var windowWasClosed = false

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        guard let window = self.window else { return }

        // First time setup or window changed
        if observedWindow !== window {
            removeObservers()
            observedWindow = window
            setupObservers(for: window)
        }

        // Always call onOpen when view moves to window
        // This handles the initial open
        if !windowWasClosed {
            onOpen?()
        }
    }

    private func setupObservers(for window: NSWindow) {
        // Observe when window becomes key (visible and focused)
        // This fires every time the window is shown, even after being closed
        becameKeyObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            if self.windowWasClosed {
                self.windowWasClosed = false
                self.onOpen?()
            }
        }

        // Observe window close
        closeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            self.windowWasClosed = true
            self.onClose?()
        }
    }

    private func removeObservers() {
        if let observer = becameKeyObserver {
            NotificationCenter.default.removeObserver(observer)
            becameKeyObserver = nil
        }
        if let observer = closeObserver {
            NotificationCenter.default.removeObserver(observer)
            closeObserver = nil
        }
    }

    deinit {
        removeObservers()
    }
}
