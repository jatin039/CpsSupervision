import Foundation
import CoreData
import Combine

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var logsThisMonth: Int = 0
    @Published var hoursThisMonth: Double = 0
    @Published var flaggedCount: Int = 0
    @Published var childrenActiveThisMonth: Int = 0

    private let context: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()

    init(context: NSManagedObjectContext) {
        self.context = context
        observeChanges()
        refresh()
    }

    func refresh() {
        let request = NSFetchRequest<SupervisionLog>(entityName: "SupervisionLog")
        let monthStart = Date().startOfMonth
        request.predicate = NSPredicate(format: "startTime >= %@", monthStart as NSDate)

        do {
            let logs = try context.fetch(request)
            logsThisMonth = logs.count
            flaggedCount = logs.filter { $0.isFlagged == true }.count
            hoursThisMonth = logs.reduce(0) { total, log in
                guard let start = log.startTime, let end = log.endTime else { return total }
                return total + end.timeIntervalSince(start).decimalHours
            }
            let childSet = Set(logs.compactMap { $0.child?.objectID })
            childrenActiveThisMonth = childSet.count
        } catch {}
    }

    private func observeChanges() {
        NotificationCenter.default
            .publisher(for: .NSManagedObjectContextObjectsDidChange, object: context)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.refresh() }
            .store(in: &cancellables)
    }
}
