import Foundation

struct ActiveUsersSnapshot: Equatable, Sendable {
    let users: [ActiveUser]
    let fetchedAt: Date
    let sourceName: String

    var activeCount: Int {
        users.count
    }
}
