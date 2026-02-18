import Foundation

struct PostHogConfiguration: Equatable, Sendable {
    let hostURL: URL
    let projectID: String
    let apiKey: String
    let activeWindowMinutes: Int
    let queryOverride: String?

    init(
        hostURL: URL,
        projectID: String,
        apiKey: String,
        activeWindowMinutes: Int = 15,
        queryOverride: String? = nil
    ) {
        self.hostURL = hostURL
        self.projectID = projectID
        self.apiKey = apiKey
        self.activeWindowMinutes = max(1, activeWindowMinutes)
        self.queryOverride = queryOverride
    }

    init?(environment: [String: String]) {
        guard
            let hostValue = environment["HOGBAR_POSTHOG_HOST"],
            let projectID = environment["HOGBAR_POSTHOG_PROJECT_ID"],
            let apiKey = environment["HOGBAR_POSTHOG_API_KEY"],
            let hostURL = URL(string: hostValue),
            !projectID.isEmpty,
            !apiKey.isEmpty
        else {
            return nil
        }

        let activeWindowMinutes = Int(environment["HOGBAR_POSTHOG_ACTIVE_WINDOW_MINUTES"] ?? "") ?? 15
        let queryOverride = environment["HOGBAR_POSTHOG_QUERY_OVERRIDE"].flatMap { value in
            value.isEmpty ? nil : value
        }

        self.init(
            hostURL: hostURL,
            projectID: projectID,
            apiKey: apiKey,
            activeWindowMinutes: activeWindowMinutes,
            queryOverride: queryOverride
        )
    }
}
