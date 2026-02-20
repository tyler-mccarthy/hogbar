import Foundation

struct PostHogConfiguration: Equatable, Sendable {
    let hostURL: URL
    let apiKey: String
    let activeWindowMinutes: Int
    let queryOverride: String?
    let preferredProjectID: String?

    init(
        hostURL: URL,
        apiKey: String,
        activeWindowMinutes: Int = 15,
        queryOverride: String? = nil,
        preferredProjectID: String? = nil
    ) {
        self.hostURL = hostURL
        self.apiKey = apiKey
        self.activeWindowMinutes = max(1, activeWindowMinutes)
        self.queryOverride = queryOverride
        self.preferredProjectID = preferredProjectID
    }

    init?(environment: [String: String]) {
        guard
            let hostValue = environment["HOGBAR_POSTHOG_HOST"],
            let apiKey = environment["HOGBAR_POSTHOG_API_KEY"],
            let hostURL = URL(string: hostValue),
            !apiKey.isEmpty
        else {
            return nil
        }

        let activeWindowMinutes = Int(environment["HOGBAR_POSTHOG_ACTIVE_WINDOW_MINUTES"] ?? "") ?? 15
        let queryOverride = environment["HOGBAR_POSTHOG_QUERY_OVERRIDE"].flatMap { value in
            value.isEmpty ? nil : value
        }
        let preferredProjectID = environment["HOGBAR_POSTHOG_PROJECT_ID"].flatMap { value in
            value.isEmpty ? nil : value
        }

        self.init(
            hostURL: hostURL,
            apiKey: apiKey,
            activeWindowMinutes: activeWindowMinutes,
            queryOverride: queryOverride,
            preferredProjectID: preferredProjectID
        )
    }
}
