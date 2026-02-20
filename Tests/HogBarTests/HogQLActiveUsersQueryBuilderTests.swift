import XCTest
@testable import HogBar

final class HogQLActiveUsersQueryBuilderTests: XCTestCase {
    func testQueryIncludesConfiguredWindowAndExpectedFields() {
        let builder = HogQLActiveUsersQueryBuilder()

        let query = builder.build(windowMinutes: 25)

        XCTAssertTrue(query.contains("INTERVAL 25 MINUTE"))
        XCTAssertTrue(query.contains("distinct_id"))
        XCTAssertTrue(query.contains("display_name"))
        XCTAssertTrue(query.contains("last_seen"))
        XCTAssertTrue(query.contains("LIMIT 50"))
    }

    func testQueryUsesMinimumWindowOfOneMinute() {
        let builder = HogQLActiveUsersQueryBuilder()

        let query = builder.build(windowMinutes: 0)

        XCTAssertTrue(query.contains("INTERVAL 1 MINUTE"))
    }
}
