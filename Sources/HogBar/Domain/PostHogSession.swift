import Foundation

struct PostHogSession: Equatable, Sendable {
    let configuration: PostHogConfiguration
    let projects: [PostHogProject]
    var selectedProjectID: String

    var selectedProject: PostHogProject? {
        projects.first { $0.id == selectedProjectID }
    }
}
