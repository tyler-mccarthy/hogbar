import Foundation

@MainActor
final class SessionController {
    private let projectsService: any PostHogProjectsServicing
    private let activeWindowMinutes: Int
    private let queryOverride: String?

    private(set) var state: AppState = .mockMode
    private(set) var suggestedHostValue: String?

    init(
        projectsService: any PostHogProjectsServicing = PostHogProjectsService(),
        activeWindowMinutes: Int = 15,
        queryOverride: String? = nil,
        suggestedHostValue: String? = nil
    ) {
        self.projectsService = projectsService
        self.activeWindowMinutes = max(1, activeWindowMinutes)
        self.queryOverride = queryOverride
        self.suggestedHostValue = suggestedHostValue
    }

    func signIn(hostValue: String, apiKeyValue: String) async -> AppState {
        let trimmedHost = hostValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedKey = apiKeyValue.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedHost.isEmpty, !trimmedKey.isEmpty else {
            state = .error(message: "Both host URL and API key are required.")
            return state
        }

        guard let hostURL = URL(string: trimmedHost) else {
            state = .error(message: "Enter a valid PostHog host URL.")
            return state
        }

        let configuration = PostHogConfiguration(
            hostURL: hostURL,
            apiKey: trimmedKey,
            activeWindowMinutes: activeWindowMinutes,
            queryOverride: queryOverride,
            preferredProjectID: nil
        )
        suggestedHostValue = trimmedHost
        return await signIn(configuration: configuration)
    }

    func signIn(configuration: PostHogConfiguration) async -> AppState {
        state = .authenticating
        suggestedHostValue = configuration.hostURL.absoluteString
        do {
            let session = try await projectsService.authenticate(configuration: configuration)
            state = .authenticated(session)
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            state = .error(message: message)
        }
        return state
    }

    func signOut() -> AppState {
        state = .mockMode
        return state
    }

    func selectProject(id: String) -> AppState {
        guard case .authenticated(var session) = state else {
            return state
        }
        guard session.projects.contains(where: { $0.id == id }) else {
            return state
        }
        session.selectedProjectID = id
        state = .authenticated(session)
        return state
    }
}
