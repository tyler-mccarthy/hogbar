import Foundation

enum PostHogActiveUsersProviderError: Error, Equatable {
    case invalidEndpoint
    case missingProject
    case unexpectedStatusCode(Int)
}

actor PostHogActiveUsersProvider: ActiveUsersProviding {
    let sourceName: String = "PostHog"

    private let configuration: PostHogConfiguration
    private let session: URLSession
    private let queryBuilder: HogQLActiveUsersQueryBuilder
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        configuration: PostHogConfiguration,
        session: URLSession = .shared,
        queryBuilder: HogQLActiveUsersQueryBuilder = HogQLActiveUsersQueryBuilder(),
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.configuration = configuration
        self.session = session
        self.queryBuilder = queryBuilder
        self.encoder = encoder
        self.decoder = decoder
    }

    func fetchActiveUsers(project: PostHogProject?) async throws -> ActiveUsersSnapshot {
        guard let project else {
            throw PostHogActiveUsersProviderError.missingProject
        }

        let hogQL = configuration.queryOverride ?? queryBuilder.build(windowMinutes: configuration.activeWindowMinutes)
        let requestBody = PostHogQueryRequest(
            query: HogQLQuery(query: hogQL),
            name: "hogbar_active_users"
        )

        guard let endpointURL = endpointURL(projectID: project.id) else {
            throw PostHogActiveUsersProviderError.invalidEndpoint
        }

        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try encoder.encode(requestBody)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PostHogActiveUsersProviderError.unexpectedStatusCode(-1)
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw PostHogActiveUsersProviderError.unexpectedStatusCode(httpResponse.statusCode)
        }

        let payload = try decoder.decode(PostHogQueryResponse.self, from: data)
        let now = Date()
        let users = payload.activeUsers(referenceDate: now)
        return ActiveUsersSnapshot(users: users, fetchedAt: now, sourceName: sourceName)
    }

    private func endpointURL(projectID: String) -> URL? {
        guard var components = URLComponents(url: configuration.hostURL, resolvingAgainstBaseURL: false) else {
            return nil
        }

        let existingPath = components.path
            .split(separator: "/")
            .map(String.init)
        let finalPath = (existingPath + ["api", "projects", projectID, "query"]).joined(separator: "/")
        components.path = "/\(finalPath)"
        components.query = nil
        return components.url
    }
}
