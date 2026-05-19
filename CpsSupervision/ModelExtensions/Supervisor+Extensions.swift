import Foundation
import CoreData

extension Supervisor {
    var wrappedName: String { name ?? "Unknown Supervisor" }
    var wrappedRelationship: String { relationship ?? "" }
    var wrappedEmail: String { email ?? "" }
    var wrappedPhone: String { phone ?? "" }
    var wrappedOrganization: String { organization ?? "" }

    var initials: String {
        let parts = wrappedName.split(separator: " ")
        let letters = parts.compactMap { $0.first }.map { String($0) }
        return letters.prefix(2).joined().uppercased()
    }

    var logsArray: [SupervisionLog] {
        let set = logs as? Set<SupervisionLog> ?? []
        return set.sorted { ($0.startTime ?? .distantPast) > ($1.startTime ?? .distantPast) }
    }

    var totalSessionsCount: Int { logsArray.count }

    var totalHoursLogged: Double {
        logsArray.reduce(0) { total, log in
            guard let start = log.startTime, let end = log.endTime else { return total }
            return total + end.timeIntervalSince(start).decimalHours
        }
    }

    static func create(in context: NSManagedObjectContext, name: String, relationship: String) -> Supervisor {
        let supervisor = Supervisor(context: context)
        supervisor.id = UUID()
        supervisor.name = name
        supervisor.relationship = relationship
        supervisor.createdAt = Date()
        return supervisor
    }
}
