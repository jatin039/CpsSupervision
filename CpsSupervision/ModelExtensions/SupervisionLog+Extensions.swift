import Foundation
import CoreData

extension SupervisionLog {
    var wrappedLocation: String { location ?? "Unknown Location" }
    var wrappedLocationType: String { locationType ?? "" }
    var wrappedActivities: String { activities ?? "" }
    var wrappedNotes: String { notes ?? "" }
    var wrappedStatus: String { status ?? Constants.LogStatus.draft.rawValue }
    var wrappedFlagReason: String { flagReason ?? "" }
    var wrappedSubmittedBy: String { submittedBy ?? "" }

    var supervisorsArray: [Supervisor] {
        let set = supervisors as? Set<Supervisor> ?? []
        return set.sorted { $0.wrappedName < $1.wrappedName }
    }

    var incidentsArray: [Incident] {
        let set = incidents as? Set<Incident> ?? []
        return set.sorted { ($0.reportedAt ?? .distantPast) < ($1.reportedAt ?? .distantPast) }
    }

    var duration: TimeInterval? {
        guard let start = startTime, let end = endTime else { return nil }
        return end.timeIntervalSince(start)
    }

    var formattedDuration: String {
        guard let d = duration else { return "In progress" }
        return d.hoursAndMinutes
    }

    var dateRangeString: String {
        guard let start = startTime else { return "No date" }
        if let end = endTime {
            return "\(start.timeString) – \(end.timeString)"
        }
        return "\(start.timeString) – ongoing"
    }

    var supervisorNames: String {
        supervisorsArray.map { $0.wrappedName }.joined(separator: ", ")
    }

    var statusColor: String {
        switch wrappedStatus {
        case Constants.LogStatus.draft.rawValue: return "orange"
        case Constants.LogStatus.submitted.rawValue: return "blue"
        case Constants.LogStatus.reviewed.rawValue: return "green"
        default: return "gray"
        }
    }

    var isSubmitted: Bool {
        wrappedStatus != Constants.LogStatus.draft.rawValue
    }

    func submit(by userName: String) {
        status = Constants.LogStatus.submitted.rawValue
        submittedBy = userName
        submittedAt = Date()
        updatedAt = Date()
    }

    static func create(in context: NSManagedObjectContext, child: Child, startTime: Date) -> SupervisionLog {
        let log = SupervisionLog(context: context)
        log.id = UUID()
        log.child = child
        log.startTime = startTime
        log.status = Constants.LogStatus.draft.rawValue
        log.isFlagged = false
        log.createdAt = Date()
        log.updatedAt = Date()
        return log
    }
}
