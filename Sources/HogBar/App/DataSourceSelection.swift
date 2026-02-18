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

    var preferredHostValue: String? {
        switch self {
        case .mock:
            return nil
        case .postHog(let configuration):
            return configuration.hostURL.absoluteString
        }
    }

    var postHogConfiguration: PostHogConfiguration? {
        if case .postHog(let configuration) = self {
            return configuration
        }
        return nil
    }
}
