import Foundation
import CoreData

extension Incident {
    var wrappedType: String { type ?? Constants.IncidentType.other.rawValue }
    var wrappedDescription: String { incidentDescription ?? "" }
    var wrappedSeverity: String { severity ?? Constants.IncidentSeverity.low.rawValue }
    var wrappedReportedBy: String { reportedBy ?? "" }
    var wrappedActionTaken: String { actionTaken ?? "" }

    var severityDisplayName: String { wrappedSeverity }

    static func create(
        in context: NSManagedObjectContext,
        log: SupervisionLog,
        type: String,
        description: String,
        severity: String,
        reportedBy: String
    ) -> Incident {
        let incident = Incident(context: context)
        incident.id = UUID()
        incident.log = log
        incident.type = type
        incident.incidentDescription = description
        incident.severity = severity
        incident.reportedBy = reportedBy
        incident.reportedAt = Date()
        return incident
    }
}
