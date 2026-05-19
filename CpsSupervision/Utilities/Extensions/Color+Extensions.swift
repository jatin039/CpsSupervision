import SwiftUI

extension Color {
    static let appPrimary = Color("AppPrimary", bundle: nil)

    static func forSeverity(_ severity: String) -> Color {
        switch severity {
        case Constants.IncidentSeverity.low.rawValue: return .green
        case Constants.IncidentSeverity.medium.rawValue: return .yellow
        case Constants.IncidentSeverity.high.rawValue: return .orange
        case Constants.IncidentSeverity.critical.rawValue: return .red
        default: return .gray
        }
    }

    static func forStatus(_ status: String) -> Color {
        switch status {
        case Constants.LogStatus.draft.rawValue: return .orange
        case Constants.LogStatus.submitted.rawValue: return .blue
        case Constants.LogStatus.reviewed.rawValue: return .green
        default: return .gray
        }
    }
}
