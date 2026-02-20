import Foundation

struct PostHogOrganisation: Equatable, Sendable {
    let id: String
    let name: String
}

struct PostHogOrganisationsResponse: Decodable, Equatable, Sendable {
    let organisations: [PostHogOrganisation]

    init(from decoder: Decoder) throws {
        if let single = try? OrganisationRecord(from: decoder) {
            organisations = [single.organisation]
            return
        }
        if let envelope = try? OrganisationEnvelope(from: decoder) {
            organisations = envelope.results.map(\.organisation)
            return
        }
        if let list = try? [OrganisationRecord](from: decoder) {
            organisations = list.map(\.organisation)
            return
        }
        throw DecodingError.typeMismatch(
            PostHogOrganisationsResponse.self,
            DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Unable to decode organisations payload"
            )
        )
    }

    private struct OrganisationEnvelope: Decodable {
        let results: [OrganisationRecord]
    }

    private struct OrganisationRecord: Decodable {
        let id: PostHogScalarString
        let name: String?

        var organisation: PostHogOrganisation {
            let finalName = name?.trimmingCharacters(in: .whitespacesAndNewlines)
            return PostHogOrganisation(
                id: id.value,
                name: (finalName?.isEmpty == false ? finalName : nil) ?? "Organisation \(id.value)"
            )
        }
    }
}
