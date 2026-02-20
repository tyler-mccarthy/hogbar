import Foundation
import XCTest
@testable import HogBar

@MainActor
final class SessionControllerTests: XCTestCase {
    func testSuccessfulSignInTransitionsToAuthenticatedState() async {
        let configuration = PostHogConfiguration(
            hostURL: URL(string: "https://us.posthog.com")!,
            apiKey: "key",
            activeWindowMinutes: 15,
            queryOverride: nil,
            preferredProjectID: nil
        )
        let projects = [
            PostHogProject(id: "1", name: "Alpha", organisationID: "99"),
            PostHogProject(id: "2", name: "Beta", organisationID: "99"),
        ]
        let session = PostHogSession(configuration: configuration, projects: projects, selectedProjectID: "1")
        let service = StubProjectsService(result: .success(session))
        let controller = SessionController(projectsService: service)

        let state = await controller.signIn(hostValue: "https://us.posthog.com", apiKeyValue: "key")

        guard case .authenticated(let authenticatedSession) = state else {
            XCTFail("Expected authenticated state")
            return
        }
        XCTAssertEqual(authenticatedSession.selectedProjectID, "1")
        XCTAssertEqual(authenticatedSession.projects.count, 2)
    }

    func testSelectProjectUpdatesAuthenticatedSession() async {
        let configuration = PostHogConfiguration(
            hostURL: URL(string: "https://us.posthog.com")!,
            apiKey: "key",
            activeWindowMinutes: 15,
            queryOverride: nil,
            preferredProjectID: nil
        )
        let projects = [
            PostHogProject(id: "1", name: "Alpha", organisationID: "99"),
            PostHogProject(id: "2", name: "Beta", organisationID: "99"),
        ]
        let session = PostHogSession(configuration: configuration, projects: projects, selectedProjectID: "1")
        let service = StubProjectsService(result: .success(session))
        let controller = SessionController(projectsService: service)
        _ = await controller.signIn(hostValue: "https://us.posthog.com", apiKeyValue: "key")

        let state = controller.selectProject(id: "2")

        guard case .authenticated(let authenticatedSession) = state else {
            XCTFail("Expected authenticated state")
            return
        }
        XCTAssertEqual(authenticatedSession.selectedProjectID, "2")
    }

    func testSignInWithMissingInputReturnsErrorState() async {
        let service = StubProjectsService(result: .failure(TestServiceError.failure))
        let controller = SessionController(projectsService: service)

        let state = await controller.signIn(hostValue: "", apiKeyValue: "")

        guard case .error(let message) = state else {
            XCTFail("Expected error state")
            return
        }
        XCTAssertTrue(message.contains("required"))
    }
}

actor StubProjectsService: PostHogProjectsServicing {
    let result: Result<PostHogSession, Error>

    init(result: Result<PostHogSession, Error>) {
        self.result = result
    }

    func authenticate(configuration: PostHogConfiguration) async throws -> PostHogSession {
        try result.get()
    }
}

enum TestServiceError: Error {
    case failure
}
