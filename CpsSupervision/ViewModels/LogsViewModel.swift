import Foundation
import CoreData
import Combine

@MainActor
class LogsViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var filterStatus: String = "all"
    @Published var filterFlaggedOnly = false
    @Published var selectedChildID: NSManagedObjectID?

    var filterPredicate: NSPredicate? {
        var predicates: [NSPredicate] = []

        if !searchText.isEmpty {
            let searchPred = NSCompoundPredicate(orPredicateWithSubpredicates: [
                NSPredicate(format: "location CONTAINS[cd] %@", searchText),
                NSPredicate(format: "activities CONTAINS[cd] %@", searchText),
                NSPredicate(format: "notes CONTAINS[cd] %@", searchText),
                NSPredicate(format: "child.name CONTAINS[cd] %@", searchText)
            ])
            predicates.append(searchPred)
        }

        if filterStatus != "all" {
            predicates.append(NSPredicate(format: "status == %@", filterStatus))
        }

        if filterFlaggedOnly {
            predicates.append(NSPredicate(format: "isFlagged == YES"))
        }

        if let childID = selectedChildID,
           let child = try? PersistenceController.shared.container.viewContext.existingObject(with: childID) {
            predicates.append(NSPredicate(format: "child == %@", child))
        }

        return predicates.isEmpty ? nil : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    func deleteLog(_ log: SupervisionLog) {
        PersistenceController.shared.delete(log)
    }
}
