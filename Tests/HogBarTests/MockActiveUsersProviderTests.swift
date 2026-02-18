import XCTest
@testable import HogBar

final class MockActiveUsersProviderTests: XCTestCase {
    func testMockProviderReturnsConsistentSnapshotShape() async throws {
        let provider = MockActiveUsersProvider()

        let firstSnapshot = try await provider.fetchActiveUsers(project: nil)
        let secondSnapshot = try await provider.fetchActiveUsers(project: nil)

        XCTAssertEqual(firstSnapshot.sourceName, "Mock")
        XCTAssertEqual(firstSnapshot.activeCount, firstSnapshot.users.count)
        XCTAssertFalse(firstSnapshot.users.isEmpty)
        XCTAssertNotEqual(firstSnapshot.users.map(\.id), secondSnapshot.users.map(\.id))
        XCTAssertGreaterThanOrEqual(firstSnapshot.activeCount, 4)
        XCTAssertLessThanOrEqual(firstSnapshot.activeCount, 7)
    }
}
