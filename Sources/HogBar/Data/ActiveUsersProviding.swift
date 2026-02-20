import Foundation

protocol ActiveUsersProviding: Sendable {
    var sourceName: String { get }
    func fetchActiveUsers(project: PostHogProject?) async throws -> ActiveUsersSnapshot
}
