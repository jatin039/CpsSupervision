import CoreData
import CloudKit

class PersistenceController: ObservableObject {
    static let shared = PersistenceController()

    let container: NSPersistentCloudKitContainer

    @Published var syncStatus: SyncStatus = .idle

    enum SyncStatus: Equatable {
        case idle, syncing, synced, error(String)
    }

    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let ctx = controller.container.viewContext

        let supervisor = Supervisor(context: ctx)
        supervisor.id = UUID()
        supervisor.name = "Jane Smith"
        supervisor.relationship = Constants.SupervisorRelationship.fosterParent.rawValue
        supervisor.phone = "555-0100"
        supervisor.createdAt = Date()

        let child = Child(context: ctx)
        child.id = UUID()
        child.name = "Alex Johnson"
        child.caseNumber = "CPS-2024-001"
        child.caseWorkerName = "Maria Garcia"
        child.caseWorkerPhone = "555-0200"
        child.createdAt = Date()
        child.updatedAt = Date()

        let log = SupervisionLog(context: ctx)
        log.id = UUID()
        log.startTime = Date().addingTimeInterval(-7200)
        log.endTime = Date()
        log.location = "123 Oak Street"
        log.locationType = Constants.LocationType.home.rawValue
        log.activities = "Homework help, dinner preparation, outdoor play, bedtime routine"
        log.notes = "Child was in good spirits. Completed all homework."
        log.isFlagged = false
        log.status = Constants.LogStatus.submitted.rawValue
        log.submittedBy = "Jane Smith"
        log.submittedAt = Date()
        log.createdAt = Date()
        log.updatedAt = Date()
        log.child = child
        log.addToSupervisors(supervisor)

        let log2 = SupervisionLog(context: ctx)
        log2.id = UUID()
        log2.startTime = Calendar.current.date(byAdding: .day, value: -1, to: Date())!.addingTimeInterval(3600)
        log2.endTime = Calendar.current.date(byAdding: .day, value: -1, to: Date())!.addingTimeInterval(10800)
        log2.location = "Riverside Park"
        log2.locationType = Constants.LocationType.park.rawValue
        log2.activities = "Outdoor play, picnic lunch, sports activities"
        log2.isFlagged = true
        log2.flagReason = "Child reported mild headache during park visit"
        log2.status = Constants.LogStatus.submitted.rawValue
        log2.submittedBy = "Jane Smith"
        log2.createdAt = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        log2.updatedAt = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        log2.child = child
        log2.addToSupervisors(supervisor)

        try? ctx.save()
        return controller
    }()

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "CpsSupervision")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            guard let description = container.persistentStoreDescriptions.first else {
                fatalError("No persistent store descriptions found.")
            }
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: Constants.cloudKitContainerID
            )
        }

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        setupSyncObserver()
    }

    private func setupSyncObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(cloudKitEventChanged(_:)),
            name: NSPersistentCloudKitContainer.eventChangedNotification,
            object: container
        )
    }

    @objc private func cloudKitEventChanged(_ notification: Notification) {
        guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                as? NSPersistentCloudKitContainer.Event else { return }

        DispatchQueue.main.async {
            if event.endDate == nil {
                self.syncStatus = .syncing
            } else if let error = event.error {
                self.syncStatus = .error(error.localizedDescription)
            } else {
                self.syncStatus = .synced
            }
        }
    }

    func save() {
        let ctx = container.viewContext
        guard ctx.hasChanges else { return }
        do {
            try ctx.save()
        } catch {
            container.viewContext.rollback()
        }
    }

    func delete(_ object: NSManagedObject) {
        container.viewContext.delete(object)
        save()
    }
}
