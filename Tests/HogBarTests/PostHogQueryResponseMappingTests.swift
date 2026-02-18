import Foundation
import XCTest
@testable import HogBar

final class PostHogQueryResponseMappingTests: XCTestCase {
    func testActiveUsersMappingParsesRowsIntoDomainUsers() throws {
        let payload = """
        {
          "columns": ["distinct_id", "display_name", "email", "last_seen"],
          "results": [
            ["user_1", "Alex Morgan", "alex@example.com", "2026-02-18T09:00:00Z"],
            ["user_2", "", "", "2026-02-18T08:30:00Z"]
          ]
        }
        """
        let data = Data(payload.utf8)

        let response = try JSONDecoder().decode(PostHogQueryResponse.self, from: data)
        let users = response.activeUsers(referenceDate: Date(timeIntervalSince1970: 1_700_000_000))

        XCTAssertEqual(users.count, 2)
        XCTAssertEqual(users[0].id, "user_1")
        XCTAssertEqual(users[0].displayName, "Alex Morgan")
        XCTAssertEqual(users[0].emailAddress, "alex@example.com")
        XCTAssertEqual(users[1].id, "user_2")
        XCTAssertEqual(users[1].displayName, "user_2")
        XCTAssertNil(users[1].emailAddress)
    }

    func testActiveUsersMappingDropsRowsWithoutDistinctIdentifier() throws {
        let payload = """
        {
          "columns": ["distinct_id", "display_name", "email", "last_seen"],
          "results": [
            ["", "No Identity", "none@example.com", "2026-02-18T09:00:00Z"],
            ["user_3", "Jamie Clarke", "jamie@example.com", "2026-02-18T08:30:00Z"]
          ]
        }
        """
        let data = Data(payload.utf8)

        let response = try JSONDecoder().decode(PostHogQueryResponse.self, from: data)
        let users = response.activeUsers()

        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users.first?.id, "user_3")
    }
}
