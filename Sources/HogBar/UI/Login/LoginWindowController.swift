import AppKit
import SwiftUI

struct LoginCredentials: Sendable, Equatable {
    let hostValue: String
    let apiKeyValue: String
}

@MainActor
final class LoginWindowController: NSWindowController, NSWindowDelegate {
    private var continuation: CheckedContinuation<LoginCredentials?, Never>?
    private var completed = false

    init() {
        super.init(window: nil)
    }

    required init?(coder: NSCoder) {
        nil
    }

    func present(initialHostValue: String?) async -> LoginCredentials? {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            self.completed = false

            let rootView = LoginView(
                initialHostValue: initialHostValue ?? "https://us.posthog.com",
                onSubmit: { [weak self] hostValue, apiKeyValue in
                    self?.complete(with: LoginCredentials(hostValue: hostValue, apiKeyValue: apiKeyValue))
                },
                onCancel: { [weak self] in
                    self?.complete(with: nil)
                }
            )

            let hostingController = NSHostingController(rootView: rootView)
            let window = NSWindow(contentViewController: hostingController)
            window.title = "PostHog Login"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.center()
            window.delegate = self
            self.window = window
            showWindow(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func windowWillClose(_ notification: Notification) {
        complete(with: nil)
    }

    private func complete(with credentials: LoginCredentials?) {
        guard !completed else {
            return
        }
        completed = true

        continuation?.resume(returning: credentials)
        continuation = nil
        window?.orderOut(nil)
        window = nil
    }
}
