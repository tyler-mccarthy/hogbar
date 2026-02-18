import Foundation

struct PostHogProjectsResponse: Decodable, Equatable, Sendable {
    let projects: [PostHogProject]

    init(from decoder: Decoder) throws {
        if let envelope = try? ProjectEnvelope(from: decoder) {
            projects = envelope.results.map(\.project)
            return
        }
        if let list = try? [ProjectRecord](from: decoder) {
            projects = list.map(\.project)
            return
        }
        if let single = try? ProjectRecord(from: decoder) {
            projects = [single.project]
            return
        }
        throw DecodingError.typeMismatch(
            PostHogProjectsResponse.self,
            DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Unable to decode projects payload"
            )
        )
    }

    private struct ProjectEnvelope: Decodable {
        let results: [ProjectRecord]
    }

    private struct ProjectRecord: Decodable {
        let id: PostHogScalarString
        let name: String?
        let organisationID: PostHogScalarString?

        enum CodingKeys: String, CodingKey {
            case id
            case name
            case organisationID = "organization_id"
            case organisation = "organization"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(PostHogScalarString.self, forKey: .id)
            name = try container.decodeIfPresent(String.self, forKey: .name)
            if let direct = try container.decodeIfPresent(PostHogScalarString.self, forKey: .organisationID) {
                organisationID = direct
            } else {
                organisationID = try container.decodeIfPresent(PostHogScalarString.self, forKey: .organisation)
            }
        }

        var project: PostHogProject {
            let finalName = name?.isEmpty == false ? name! : "Project \(id.value)"
            let finalOrganisationID = organisationID?.value ?? "unknown"
            return PostHogProject(id: id.value, name: finalName, organisationID: finalOrganisationID)
        }
    }
}
