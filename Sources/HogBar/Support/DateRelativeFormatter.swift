import Foundation

final class DateRelativeFormatter: Sendable {
    private let formatter: RelativeDateTimeFormatter

    init() {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        self.formatter = formatter
    }

    func string(for date: Date, relativeTo referenceDate: Date = Date()) -> String {
        formatter.localizedString(for: date, relativeTo: referenceDate)
    }
}
