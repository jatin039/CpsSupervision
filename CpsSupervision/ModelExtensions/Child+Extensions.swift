import Foundation
import CoreData
import UIKit

extension Child {
    var wrappedName: String { name ?? "Unknown Child" }
    var wrappedCaseNumber: String { caseNumber ?? "No Case Number" }
    var wrappedNotes: String { notes ?? "" }
    var wrappedCaseWorkerName: String { caseWorkerName ?? "" }
    var wrappedCaseWorkerPhone: String { caseWorkerPhone ?? "" }

    var photo: UIImage? {
        guard let data = photoData else { return nil }
        return UIImage(data: data)
    }

    var logsArray: [SupervisionLog] {
        let set = logs as? Set<SupervisionLog> ?? []
        return set.sorted { ($0.startTime ?? .distantPast) > ($1.startTime ?? .distantPast) }
    }

    var logsThisMonth: [SupervisionLog] {
        logsArray.filter { ($0.startTime ?? .distantPast).isThisMonth }
    }

    var flaggedLogsCount: Int {
        logsArray.filter { $0.isFlagged == true }.count
    }

    var totalHoursThisMonth: Double {
        logsThisMonth.reduce(0) { total, log in
            guard let start = log.startTime, let end = log.endTime else { return total }
            return total + end.timeIntervalSince(start).decimalHours
        }
    }

    var formattedDateOfBirth: String {
        guard let dob = dateOfBirth else { return "Not recorded" }
        return dob.formatted(date: .abbreviated, time: .omitted)
    }

    var age: String {
        guard let dob = dateOfBirth else { return "Unknown" }
        let years = Calendar.current.dateComponents([.year], from: dob, to: Date()).year ?? 0
        return "\(years) years old"
    }

    static func create(in context: NSManagedObjectContext, name: String, caseNumber: String) -> Child {
        let child = Child(context: context)
        child.id = UUID()
        child.name = name
        child.caseNumber = caseNumber
        child.createdAt = Date()
        child.updatedAt = Date()
        return child
    }
}
