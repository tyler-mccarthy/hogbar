import AppKit
import Foundation

@MainActor
final class ActiveUsersMenuComposer {
    private let relativeFormatter: DateRelativeFormatter

    init(relativeFormatter: DateRelativeFormatter) {
        self.relativeFormatter = relativeFormatter
    }

    func makeMenu(
        snapshot: ActiveUsersSnapshot?,
        errorMessage: String?,
        appState: AppState,
        target: AnyObject,
        refreshSelector: Selector,
        signInSelector: Selector,
        signOutSelector: Selector,
        selectProjectSelector: Selector,
        quitSelector: Selector
    ) -> NSMenu {
        let menu = NSMenu()

        if let snapshot {
            let countItem = NSMenuItem(
                title: "Active users: \(snapshot.activeCount)",
                action: nil,
                keyEquivalent: ""
            )
            countItem.isEnabled = false
            menu.addItem(countItem)

            let updateItem = NSMenuItem(
                title: "Updated \(relativeFormatter.string(for: snapshot.fetchedAt)) via \(snapshot.sourceName)",
                action: nil,
                keyEquivalent: ""
            )
            updateItem.isEnabled = false
            menu.addItem(updateItem)
            menu.addItem(.separator())

            if snapshot.users.isEmpty {
                let emptyItem = NSMenuItem(title: "No active users", action: nil, keyEquivalent: "")
                emptyItem.isEnabled = false
                menu.addItem(emptyItem)
            } else {
                snapshot.users.forEach { user in
                    let identity = user.emailAddress.map { "\(user.displayName) (\($0))" } ?? user.displayName
                    let row = NSMenuItem(
                        title: "\(identity) · \(relativeFormatter.string(for: user.lastSeenAt))",
                        action: nil,
                        keyEquivalent: ""
                    )
                    row.isEnabled = false
                    menu.addItem(row)
                }
            }
        } else if let errorMessage {
            let titleItem = NSMenuItem(title: "Unable to refresh active users", action: nil, keyEquivalent: "")
            titleItem.isEnabled = false
            menu.addItem(titleItem)

            let messageItem = NSMenuItem(title: errorMessage, action: nil, keyEquivalent: "")
            messageItem.isEnabled = false
            menu.addItem(messageItem)
        } else {
            let loadingItem = NSMenuItem(title: "Loading active users…", action: nil, keyEquivalent: "")
            loadingItem.isEnabled = false
            menu.addItem(loadingItem)
        }

        if case .error(let message) = appState {
            menu.addItem(.separator())
            let authErrorItem = NSMenuItem(title: "Authentication issue: \(message)", action: nil, keyEquivalent: "")
            authErrorItem.isEnabled = false
            menu.addItem(authErrorItem)
        }

        menu.addItem(.separator())

        switch appState {
        case .authenticated(let session):
            if let selectedProject = session.selectedProject {
                let selectedItem = NSMenuItem(
                    title: "Current project: \(selectedProject.name)",
                    action: nil,
                    keyEquivalent: ""
                )
                selectedItem.isEnabled = false
                menu.addItem(selectedItem)
            }

            let switchItem = NSMenuItem(title: "Switch project", action: nil, keyEquivalent: "")
            let submenu = NSMenu()
            session.projects.forEach { project in
                let projectItem = NSMenuItem(
                    title: project.name,
                    action: selectProjectSelector,
                    keyEquivalent: ""
                )
                projectItem.target = target
                projectItem.state = project.id == session.selectedProjectID ? .on : .off
                projectItem.representedObject = project.id
                submenu.addItem(projectItem)
            }
            switchItem.submenu = submenu
            menu.addItem(switchItem)

            let signOutItem = NSMenuItem(title: "Sign out", action: signOutSelector, keyEquivalent: "")
            signOutItem.target = target
            menu.addItem(signOutItem)
        case .authenticating:
            let loadingAuthItem = NSMenuItem(title: "Signing in…", action: nil, keyEquivalent: "")
            loadingAuthItem.isEnabled = false
            menu.addItem(loadingAuthItem)
        case .mockMode, .error:
            let signInItem = NSMenuItem(title: "Sign in to PostHog…", action: signInSelector, keyEquivalent: "l")
            signInItem.target = target
            menu.addItem(signInItem)
        }

        menu.addItem(.separator())

        let refreshItem = NSMenuItem(title: "Refresh now", action: refreshSelector, keyEquivalent: "r")
        refreshItem.target = target
        menu.addItem(refreshItem)

        let quitItem = NSMenuItem(title: "Quit HogBar", action: quitSelector, keyEquivalent: "q")
        quitItem.target = target
        menu.addItem(quitItem)

        return menu
    }
}
