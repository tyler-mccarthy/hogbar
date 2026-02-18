import Foundation

actor MockActiveUsersProvider: ActiveUsersProviding {
    let sourceName: String = "Mock"

    private var refreshCount: Int = 0

    private let baseUsers: [(id: String, name: String, email: String)] = [
        ("u_001", "Alex Morgan", "alex.morgan@example.com"),
        ("u_002", "Sam Taylor", "sam.taylor@example.com"),
        ("u_003", "Jordan Lee", "jordan.lee@example.com"),
        ("u_004", "Casey Patel", "casey.patel@example.com"),
        ("u_005", "Jamie Clarke", "jamie.clarke@example.com"),
        ("u_006", "Riley Harris", "riley.harris@example.com"),
        ("u_007", "Avery Evans", "avery.evans@example.com"),
        ("u_008", "Charlie Singh", "charlie.singh@example.com"),
    ]

    func fetchActiveUsers() async throws -> ActiveUsersSnapshot {
        refreshCount += 1
        let now = Date()
        let startIndex = refreshCount % baseUsers.count
        let activeTotal = 4 + (refreshCount % 4)
        let rotatedUsers = (0..<activeTotal).map { offset in
            baseUsers[(startIndex + offset) % baseUsers.count]
        }

        let users = rotatedUsers.enumerated().map { entry in
            let index = entry.offset
            let user = entry.element
            let secondsAgo = TimeInterval((index * 91 + refreshCount * 37) % 780)
            return ActiveUser(
                id: user.id,
                displayName: user.name,
                emailAddress: user.email,
                lastSeenAt: now.addingTimeInterval(-secondsAgo)
            )
        }
        .sorted { $0.lastSeenAt > $1.lastSeenAt }

        return ActiveUsersSnapshot(
            users: users,
            fetchedAt: now,
            sourceName: sourceName
        )
    }
}
