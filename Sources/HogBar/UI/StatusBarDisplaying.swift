import Foundation

@MainActor
protocol StatusBarDisplaying: AnyObject {
    func apply(snapshot: ActiveUsersSnapshot?, errorMessage: String?, appState: AppState)
}
