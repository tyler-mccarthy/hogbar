import Foundation

struct PostHogScalarString: Decodable, Equatable, Sendable {
    let value: String

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let stringValue = try? container.decode(String.self) {
            value = stringValue
            return
        }
        if let intValue = try? container.decode(Int.self) {
            value = String(intValue)
            return
        }
        if let doubleValue = try? container.decode(Double.self) {
            value = String(Int(doubleValue))
            return
        }
        throw DecodingError.typeMismatch(
            PostHogScalarString.self,
            DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Unsupported scalar value"
            )
        )
    }
}
