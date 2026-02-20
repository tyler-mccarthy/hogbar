import AppKit
import Foundation

@MainActor
final class StatusBarController: NSObject, StatusBarDisplaying {
    private let statusItem: NSStatusItem
    private let menuComposer: ActiveUsersMenuComposer
    private var refreshHandler: (() -> Void)?
    private var signInHandler: (() -> Void)?
    private var signOutHandler: (() -> Void)?
    private var projectSelectionHandler: ((String) -> Void)?
    private var latestSnapshot: ActiveUsersSnapshot?
    private var latestErrorMessage: String?
    private var appState: AppState = .mockMode

    init(
        relativeFormatter: DateRelativeFormatter,
        statusBar: NSStatusBar = .system
    ) {
        self.statusItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        self.menuComposer = ActiveUsersMenuComposer(relativeFormatter: relativeFormatter)
        super.init()
        statusItem.button?.title = "👥 --"
        renderMenu()
    }

    func setHandlers(
        refreshHandler: @escaping () -> Void,
        signInHandler: @escaping () -> Void,
        signOutHandler: @escaping () -> Void,
        projectSelectionHandler: @escaping (String) -> Void
    ) {
        self.refreshHandler = refreshHandler
        self.signInHandler = signInHandler
        self.signOutHandler = signOutHandler
        self.projectSelectionHandler = projectSelectionHandler
        renderMenu()
    }

    func apply(snapshot: ActiveUsersSnapshot?, errorMessage: String?, appState: AppState) {
        latestSnapshot = snapshot
        latestErrorMessage = errorMessage
        self.appState = appState
        updateStatusButton()
        renderMenu()
    }

    private func renderMenu() {
        statusItem.menu = menuComposer.makeMenu(
            snapshot: latestSnapshot,
            errorMessage: latestErrorMessage,
            appState: appState,
            target: self,
            refreshSelector: #selector(refreshNow),
            signInSelector: #selector(signInNow),
            signOutSelector: #selector(signOutNow),
            selectProjectSelector: #selector(selectProject(_:)),
            quitSelector: #selector(quitApp)
        )
    }

    private func updateStatusButton() {
        if case .authenticating = appState {
            statusItem.button?.title = "⏳"
            statusItem.button?.toolTip = "Signing in"
            return
        }
        if let snapshot = latestSnapshot {
            statusItem.button?.title = "👥 \(snapshot.activeCount)"
            statusItem.button?.toolTip = "Active users: \(snapshot.activeCount)"
            return
        }
        if case .error = appState {
            statusItem.button?.title = "⚠︎"
            statusItem.button?.toolTip = "Authentication issue"
            return
        }
        statusItem.button?.title = "👥 --"
        statusItem.button?.toolTip = "Active users unavailable"
    }

    @objc private func refreshNow() {
        refreshHandler?()
    }

    @objc private func signInNow() {
        signInHandler?()
    }

    @objc private func signOutNow() {
        signOutHandler?()
    }

    @objc private func selectProject(_ sender: NSMenuItem) {
        guard let projectID = sender.representedObject as? String else {
            return
        }
        projectSelectionHandler?(projectID)
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
