import Foundation

struct PostHogQueryResponse: Decodable, Equatable, Sendable {
    let columns: [String]
    let results: [[PostHogCell]]

    func activeUsers(referenceDate: Date = Date()) -> [ActiveUser] {
        let columnIndexes = Dictionary(uniqueKeysWithValues: columns.enumerated().map { ($1, $0) })
        guard let distinctIDIndex = columnIndexes["distinct_id"] else {
            return []
        }

        let displayNameIndex = columnIndexes["display_name"]
        let emailIndex = columnIndexes["email"]
        let lastSeenIndex = columnIndexes["last_seen"]

        return results.compactMap { row in
            guard row.indices.contains(distinctIDIndex) else {
                return nil
            }

            let distinctID = row[distinctIDIndex].stringValue?.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let id = distinctID, !id.isEmpty else {
                return nil
            }

            let rawName = displayNameIndex.flatMap { row[safe: $0]?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) }
            let displayName = (rawName?.isEmpty == false) ? rawName! : id

            let rawEmail = emailIndex.flatMap { row[safe: $0]?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) }
            let email = (rawEmail?.isEmpty == false) ? rawEmail : nil

            let parsedDate = lastSeenIndex
                .flatMap { row[safe: $0]?.stringValue }
                .flatMap { PostHogDateParser.shared.parse($0) } ?? referenceDate

            return ActiveUser(
                id: id,
                displayName: displayName,
                emailAddress: email,
                lastSeenAt: parsedDate
            )
        }
        .sorted { $0.lastSeenAt > $1.lastSeenAt }
    }
}

enum PostHogCell: Decodable, Equatable, Sendable {
    case string(String)
    case number(Double)
    case boolean(Bool)
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .boolean(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else {
            throw DecodingError.typeMismatch(
                PostHogCell.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unsupported PostHog cell value type"
                )
            )
        }
    }

    var stringValue: String? {
        switch self {
        case .string(let value):
            return value
        case .number(let value):
            return String(value)
        case .boolean(let value):
            return String(value)
        case .null:
            return nil
        }
    }
}

private final class PostHogDateParser: @unchecked Sendable {
    static let shared = PostHogDateParser()

    private let iso8601WithFractions = ISO8601DateFormatter()
    private let iso8601 = ISO8601DateFormatter()

    private init() {
        iso8601WithFractions.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        iso8601.formatOptions = [.withInternetDateTime]
    }

    func parse(_ value: String) -> Date? {
        iso8601WithFractions.date(from: value) ?? iso8601.date(from: value)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
