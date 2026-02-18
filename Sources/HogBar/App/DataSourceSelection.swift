import Foundation

enum DataSourceSelection: Sendable, Equatable {
    case mock
    case postHog(PostHogConfiguration)

    static func fromEnvironment(_ environment: [String: String] = ProcessInfo.processInfo.environment) -> DataSourceSelection {
        if let configuration = PostHogConfiguration(environment: environment) {
            return .postHog(configuration)
        }
        return .mock
    }

    func makeProvider(session: URLSession = .shared) -> any ActiveUsersProviding {
        switch self {
        case .mock:
            return MockActiveUsersProvider()
        case .postHog(let configuration):
            return PostHogActiveUsersProvider(configuration: configuration, session: session)
        }
    }
}
