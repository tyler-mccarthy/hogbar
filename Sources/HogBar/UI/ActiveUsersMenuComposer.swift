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
        target: AnyObject,
        refreshSelector: Selector,
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
