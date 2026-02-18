import Foundation

protocol ActiveUsersProviding: Sendable {
    var sourceName: String { get }
    func fetchActiveUsers() async throws -> ActiveUsersSnapshot
}
