import Foundation

@MainActor
final class ActiveUsersCoordinator {
    private let provider: any ActiveUsersProviding
    private let statusBarController: StatusBarController
    private let refreshIntervalSeconds: TimeInterval
    private var refreshTask: Task<Void, Never>?

    init(
        provider: any ActiveUsersProviding,
        statusBarController: StatusBarController,
        refreshIntervalSeconds: TimeInterval = 60
    ) {
        self.provider = provider
        self.statusBarController = statusBarController
        self.refreshIntervalSeconds = max(5, refreshIntervalSeconds)
    }

    func start() {
        guard refreshTask == nil else {
            return
        }

        refreshTask = Task { [weak self] in
            guard let self else {
                return
            }

            await self.refreshOnce()
            while !Task.isCancelled {
                let sleepNanoseconds = UInt64(self.refreshIntervalSeconds * 1_000_000_000)
                try? await Task.sleep(nanoseconds: sleepNanoseconds)
                if Task.isCancelled {
                    break
                }
                await self.refreshOnce()
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
            await self.refreshOnce()
        }
    }

    private func refreshOnce() async {
        do {
            let snapshot = try await provider.fetchActiveUsers()
            statusBarController.update(snapshot: snapshot)
        } catch {
            statusBarController.updateError(error)
        }
    }
}
