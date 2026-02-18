import Foundation
import XCTest
@testable import HogBar

@MainActor
final class ActiveUsersCoordinatorProjectSwitchTests: XCTestCase {
    func testProjectSwitchRefreshesUsingSelectedProject() async {
        let mockProvider = CoordinatorStubProvider(sourceName: "Mock")
        let postHogProvider = CoordinatorStubProvider(sourceName: "PostHogTest")
        let statusDisplay = CoordinatorStatusDisplay()
        let firstSnapshotExpectation = expectation(description: "First PostHog snapshot")
        let secondSnapshotExpectation = expectation(description: "Second PostHog snapshot")
        var receivedPostHogSnapshots = 0
        statusDisplay.onSnapshot = { snapshot in
            if snapshot.sourceName == "PostHogTest" {
                receivedPostHogSnapshots += 1
                if receivedPostHogSnapshots == 1 {
                    firstSnapshotExpectation.fulfill()
                }
                if receivedPostHogSnapshots == 2 {
                    secondSnapshotExpectation.fulfill()
                }
            }
        }

        let coordinator = ActiveUsersCoordinator(
            statusBarDisplay: statusDisplay,
            refreshIntervalSeconds: 60,
            mockProvider: mockProvider,
            postHogProviderFactory: { _ in postHogProvider }
        )

        let configuration = PostHogConfiguration(
            hostURL: URL(string: "https://us.posthog.com")!,
            apiKey: "key",
            activeWindowMinutes: 15,
            queryOverride: nil,
            preferredProjectID: nil
        )
        let projects = [
            PostHogProject(id: "project_one", name: "One", organisationID: "org_1"),
            PostHogProject(id: "project_two", name: "Two", organisationID: "org_1"),
        ]

        coordinator.applyState(
            .authenticated(
                PostHogSession(
                    configuration: configuration,
                    projects: projects,
                    selectedProjectID: "project_one"
                )
            )
        )

        await fulfillment(of: [firstSnapshotExpectation], timeout: 2.0)

        coordinator.applyState(
            .authenticated(
                PostHogSession(
                    configuration: configuration,
                    projects: projects,
                    selectedProjectID: "project_two"
                )
            )
        )

        await fulfillment(of: [secondSnapshotExpectation], timeout: 2.0)

        let requestedProjectIDs = await postHogProvider.requestedProjectIDs()
        XCTAssertEqual(requestedProjectIDs, ["project_one", "project_two"])
    }
}

actor CoordinatorStubProvider: ActiveUsersProviding {
    let sourceName: String
    private var requestedProjectIDsStorage: [String?] = []

    init(sourceName: String) {
        self.sourceName = sourceName
    }

    func fetchActiveUsers(project: PostHogProject?) async throws -> ActiveUsersSnapshot {
        requestedProjectIDsStorage.append(project?.id)
        let user = ActiveUser(
            id: project?.id ?? "mock_user",
            displayName: project?.name ?? "Mock User",
            emailAddress: nil,
            lastSeenAt: Date()
        )
        return ActiveUsersSnapshot(users: [user], fetchedAt: Date(), sourceName: sourceName)
    }

    func requestedProjectIDs() -> [String?] {
        requestedProjectIDsStorage
    }
}

@MainActor
final class CoordinatorStatusDisplay: StatusBarDisplaying {
    var onSnapshot: ((ActiveUsersSnapshot) -> Void)?

    func apply(snapshot: ActiveUsersSnapshot?, errorMessage: String?, appState: AppState) {
        if let snapshot {
            onSnapshot?(snapshot)
        }
    }
}
