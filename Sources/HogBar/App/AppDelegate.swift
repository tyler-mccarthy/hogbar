import AppKit
import Foundation

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var coordinator: ActiveUsersCoordinator?
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let sourceSelection = DataSourceSelection.fromEnvironment()
        let provider = sourceSelection.makeProvider()
        let statusBarController = StatusBarController(relativeFormatter: DateRelativeFormatter())
        let coordinator = ActiveUsersCoordinator(
            provider: provider,
            statusBarController: statusBarController,
            refreshIntervalSeconds: 60
        )

        statusBarController.setRefreshHandler { [weak self] in
            self?.coordinator?.requestManualRefresh()
        }

        self.statusBarController = statusBarController
        self.coordinator = coordinator
        self.coordinator?.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        coordinator?.stop()
    }
}
