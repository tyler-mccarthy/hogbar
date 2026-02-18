import Foundation

struct ActiveUser: Identifiable, Equatable, Sendable {
    let id: String
    let displayName: String
    let emailAddress: String?
    let lastSeenAt: Date
}
