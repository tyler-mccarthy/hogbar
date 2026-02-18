import AppKit
import Foundation

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let sessionController: SessionController
    private let loginWindowController = LoginWindowController()
    private let initialDataSource: DataSourceSelection

    private var coordinator: ActiveUsersCoordinator?
    private var statusBarController: StatusBarController?

    override init() {
        initialDataSource = DataSourceSelection.fromEnvironment()
        let configuration = initialDataSource.postHogConfiguration
        sessionController = SessionController(
            activeWindowMinutes: configuration?.activeWindowMinutes ?? 15,
            queryOverride: configuration?.queryOverride,
            suggestedHostValue: initialDataSource.preferredHostValue
        )
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let statusBarController = StatusBarController(relativeFormatter: DateRelativeFormatter())
        let coordinator = ActiveUsersCoordinator(
            statusBarDisplay: statusBarController,
            refreshIntervalSeconds: 60
        )

        statusBarController.setHandlers(
            refreshHandler: { [weak self] in
                self?.coordinator?.requestManualRefresh()
            },
            signInHandler: { [weak self] in
                self?.beginInteractiveSignIn()
            },
            signOutHandler: { [weak self] in
                self?.handleSignOut()
            },
            projectSelectionHandler: { [weak self] projectID in
                self?.handleProjectSwitch(projectID: projectID)
            }
        )

        self.statusBarController = statusBarController
        self.coordinator = coordinator
        applyState(sessionController.state)
        self.coordinator?.start()

        if let configuration = initialDataSource.postHogConfiguration {
            Task { [weak self] in
                guard let self else {
                    return
                }
                let state = await self.sessionController.signIn(configuration: configuration)
                self.applyState(state)
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        coordinator?.stop()
    }

    private func beginInteractiveSignIn() {
        Task { [weak self] in
            guard let self else {
                return
            }
            let credentials = await self.loginWindowController.present(
                initialHostValue: self.sessionController.suggestedHostValue
            )
            guard let credentials else {
                return
            }
            let state = await self.sessionController.signIn(
                hostValue: credentials.hostValue,
                apiKeyValue: credentials.apiKeyValue
            )
            self.applyState(state)
        }
    }

    private func handleSignOut() {
        let state = sessionController.signOut()
        applyState(state)
    }

    private func handleProjectSwitch(projectID: String) {
        let state = sessionController.selectProject(id: projectID)
        applyState(state)
    }

    private func applyState(_ state: AppState) {
        coordinator?.applyState(state)
    }
}
