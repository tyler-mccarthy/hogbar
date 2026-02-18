import AppKit
import Foundation

@MainActor
final class StatusBarController: NSObject {
    private let statusItem: NSStatusItem
    private let menuComposer: ActiveUsersMenuComposer
    private var refreshHandler: (() -> Void)?

    init(
        relativeFormatter: DateRelativeFormatter,
        statusBar: NSStatusBar = .system
    ) {
        self.statusItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        self.menuComposer = ActiveUsersMenuComposer(relativeFormatter: relativeFormatter)
        super.init()
        statusItem.button?.title = "👥 --"
        renderMenu(snapshot: nil, errorMessage: nil)
    }

    func setRefreshHandler(_ refreshHandler: @escaping () -> Void) {
        self.refreshHandler = refreshHandler
    }

    func update(snapshot: ActiveUsersSnapshot) {
        statusItem.button?.title = "👥 \(snapshot.activeCount)"
        statusItem.button?.toolTip = "Active users: \(snapshot.activeCount)"
        renderMenu(snapshot: snapshot, errorMessage: nil)
    }

    func updateError(_ error: Error) {
        statusItem.button?.title = "⚠︎"
        statusItem.button?.toolTip = "Refresh failed"
        renderMenu(snapshot: nil, errorMessage: error.localizedDescription)
    }

    private func renderMenu(snapshot: ActiveUsersSnapshot?, errorMessage: String?) {
        statusItem.menu = menuComposer.makeMenu(
            snapshot: snapshot,
            errorMessage: errorMessage,
            target: self,
            refreshSelector: #selector(refreshNow),
            quitSelector: #selector(quitApp)
        )
    }

    @objc private func refreshNow() {
        refreshHandler?()
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
