import Foundation

struct HogQLActiveUsersQueryBuilder {
    func build(windowMinutes: Int) -> String {
        let safeWindow = max(1, windowMinutes)
        return """
        SELECT
            any(distinct_id) AS distinct_id,
            coalesce(any(properties.$name), any(properties.name), any(person.properties.name), any(person.properties.email), any(distinct_id)) AS display_name,
            coalesce(any(properties.$email), any(properties.email), any(person.properties.email), '') AS email,
            max(timestamp) AS last_seen
        FROM events
        WHERE timestamp >= now() - INTERVAL \(safeWindow) MINUTE
        GROUP BY distinct_id
        ORDER BY last_seen DESC
        LIMIT 50
        """
    }
}
