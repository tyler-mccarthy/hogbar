import Foundation

enum AppState: Equatable, Sendable {
    case mockMode
    case authenticating
    case authenticated(PostHogSession)
    case error(message: String)

    var currentSession: PostHogSession? {
        if case .authenticated(let session) = self {
            return session
        }
        return nil
    }
}
