import SwiftUI

@main
struct HogBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            VStack(spacing: 10) {
                Text("HogBar runs in your menu bar.")
                Text("Use the menu bar icon to see active users.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
        }
    }
}
