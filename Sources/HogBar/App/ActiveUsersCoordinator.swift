import Foundation

@MainActor
final class ActiveUsersCoordinator {
    private let statusBarDisplay: any StatusBarDisplaying
    private let refreshIntervalSeconds: TimeInterval
    private let mockProvider: any ActiveUsersProviding
    private let postHogProviderFactory: @Sendable (PostHogConfiguration) -> any ActiveUsersProviding

    private var refreshTask: Task<Void, Never>?
    private var activeProvider: any ActiveUsersProviding
    private var selectedProject: PostHogProject?
    private var latestSnapshot: ActiveUsersSnapshot?
    private var latestErrorMessage: String?
    private var appState: AppState = .mockMode

    init(
        statusBarDisplay: any StatusBarDisplaying,
        refreshIntervalSeconds: TimeInterval = 60,
        mockProvider: any ActiveUsersProviding = MockActiveUsersProvider(),
        postHogProviderFactory: @escaping @Sendable (PostHogConfiguration) -> any ActiveUsersProviding = { configuration in
            PostHogActiveUsersProvider(configuration: configuration)
        }
    ) {
        self.statusBarDisplay = statusBarDisplay
        self.refreshIntervalSeconds = max(5, refreshIntervalSeconds)
        self.mockProvider = mockProvider
        self.postHogProviderFactory = postHogProviderFactory
        self.activeProvider = mockProvider
        statusBarDisplay.apply(snapshot: nil, errorMessage: nil, appState: appState)
    }

    func start() {
        guard refreshTask == nil else {
            return
        }

        refreshTask = Task { [weak self] in
            guard let self else {
                return
            }

            await self.refreshNow()
            while !Task.isCancelled {
                let sleepNanoseconds = UInt64(self.refreshIntervalSeconds * 1_000_000_000)
                try? await Task.sleep(nanoseconds: sleepNanoseconds)
                if Task.isCancelled {
                    break
                }
                if case .authenticating = self.appState {
                    continue
                }
                await self.refreshNow()
            }
        }
    }

    func stop() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    func requestManualRefresh() {
        Task { [weak self] in
            guard let self else {
                return
            }
            await self.refreshNow()
        }
    }

    func applyState(_ state: AppState) {
        appState = state
        latestErrorMessage = nil

        switch state {
        case .mockMode:
            activeProvider = mockProvider
            selectedProject = nil
            latestSnapshot = nil
            statusBarDisplay.apply(snapshot: nil, errorMessage: nil, appState: appState)
            requestManualRefresh()
        case .authenticating:
            statusBarDisplay.apply(snapshot: latestSnapshot, errorMessage: nil, appState: appState)
        case .authenticated(let session):
            activeProvider = postHogProviderFactory(session.configuration)
            selectedProject = session.selectedProject
            latestSnapshot = nil
            statusBarDisplay.apply(snapshot: nil, errorMessage: nil, appState: appState)
            requestManualRefresh()
        case .error(let message):
            activeProvider = mockProvider
            selectedProject = nil
            latestErrorMessage = message
            statusBarDisplay.apply(snapshot: latestSnapshot, errorMessage: message, appState: appState)
            requestManualRefresh()
        }
    }

    private func refreshNow() async {
        if case .authenticating = appState {
            statusBarDisplay.apply(snapshot: latestSnapshot, errorMessage: latestErrorMessage, appState: appState)
            return
        }

        do {
            let snapshot = try await activeProvider.fetchActiveUsers(project: selectedProject)
            latestSnapshot = snapshot
            latestErrorMessage = nil
            statusBarDisplay.apply(snapshot: snapshot, errorMessage: nil, appState: appState)
        } catch {
            latestErrorMessage = error.localizedDescription
            statusBarDisplay.apply(
                snapshot: latestSnapshot,
                errorMessage: error.localizedDescription,
                appState: appState
            )
        }
    }
}
