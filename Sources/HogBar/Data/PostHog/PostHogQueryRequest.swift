import Foundation

struct PostHogQueryRequest: Encodable, Sendable {
    let query: HogQLQuery
    let name: String?

    init(query: HogQLQuery, name: String? = nil) {
        self.query = query
        self.name = name
    }
}

struct HogQLQuery: Encodable, Sendable {
    let kind: String
    let query: String

    init(query: String) {
        self.kind = "HogQLQuery"
        self.query = query
    }
}
