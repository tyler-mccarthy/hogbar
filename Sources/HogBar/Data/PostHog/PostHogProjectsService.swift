import Foundation

enum PostHogProjectsServiceError: Error, Equatable, LocalizedError {
    case invalidHost
    case unauthorised
    case unexpectedStatusCode(Int)
    case noOrganisationsAvailable
    case noProjectsAvailable

    var errorDescription: String? {
        switch self {
        case .invalidHost:
            return "The PostHog host URL is invalid."
        case .unauthorised:
            return "Authentication failed. Check your API key permissions."
        case .unexpectedStatusCode(let code):
            return "PostHog request failed with status code \(code)."
        case .noOrganisationsAvailable:
            return "No organisations are available for this account."
        case .noProjectsAvailable:
            return "No projects are available for this account."
        }
    }
}

actor PostHogProjectsService {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
    }

    func authenticate(configuration: PostHogConfiguration) async throws -> PostHogSession {
        let organisations = try await fetchOrganisations(configuration: configuration)
        guard let organisation = organisations.first else {
            throw PostHogProjectsServiceError.noOrganisationsAvailable
        }

        let projects = try await fetchProjects(configuration: configuration, organisationID: organisation.id)
        guard !projects.isEmpty else {
            throw PostHogProjectsServiceError.noProjectsAvailable
        }

        let selectedProjectID = configuration.preferredProjectID.flatMap { preferredID in
            projects.first(where: { $0.id == preferredID })?.id
        } ?? projects[0].id

        return PostHogSession(
            configuration: configuration,
            projects: projects,
            selectedProjectID: selectedProjectID
        )
    }

    private func fetchOrganisations(configuration: PostHogConfiguration) async throws -> [PostHogOrganisation] {
        let request = try makeRequest(
            configuration: configuration,
            pathComponents: ["api", "organizations", "@current"],
            method: "GET"
        )
        let data = try await execute(request)
        let payload = try decoder.decode(PostHogOrganisationsResponse.self, from: data)
        return payload.organisations
    }

    private func fetchProjects(configuration: PostHogConfiguration, organisationID: String) async throws -> [PostHogProject] {
        let request = try makeRequest(
            configuration: configuration,
            pathComponents: ["api", "organizations", organisationID, "projects"],
            method: "GET"
        )
        let data = try await execute(request)
        let payload = try decoder.decode(PostHogProjectsResponse.self, from: data)
        return payload.projects
    }

    private func makeRequest(
        configuration: PostHogConfiguration,
        pathComponents: [String],
        method: String
    ) throws -> URLRequest {
        guard let url = endpointURL(baseURL: configuration.hostURL, pathComponents: pathComponents) else {
            throw PostHogProjectsServiceError.invalidHost
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private func execute(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PostHogProjectsServiceError.unexpectedStatusCode(-1)
        }
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw PostHogProjectsServiceError.unauthorised
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw PostHogProjectsServiceError.unexpectedStatusCode(httpResponse.statusCode)
        }
        return data
    }

    private func endpointURL(baseURL: URL, pathComponents: [String]) -> URL? {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            return nil
        }
        let existingPath = components.path
            .split(separator: "/")
            .map(String.init)
        let mergedPath = (existingPath + pathComponents).joined(separator: "/")
        components.path = "/\(mergedPath)"
        components.query = nil
        return components.url
    }
}
