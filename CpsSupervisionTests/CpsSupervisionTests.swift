import XCTest
import CoreData
@testable import CpsSupervision

final class CpsSupervisionTests: XCTestCase {
    var context: NSManagedObjectContext!

    override func setUpWithError() throws {
        context = PersistenceController(inMemory: true).container.viewContext
    }

    override func tearDownWithError() throws {
        context = nil
    }

    // MARK: - Child

    func testCreateChild() throws {
        let child = Child.create(in: context, name: "Test Child", caseNumber: "CPS-001")
        try context.save()
        XCTAssertEqual(child.wrappedName, "Test Child")
        XCTAssertEqual(child.wrappedCaseNumber, "CPS-001")
        XCTAssertNotNil(child.id)
        XCTAssertNotNil(child.createdAt)
    }

    func testChildLogsRelationship() throws {
        let child = Child.create(in: context, name: "Child A", caseNumber: "001")
        let log = SupervisionLog.create(in: context, child: child, startTime: Date())
        log.endTime = Date().addingTimeInterval(3600)
        log.location = "Test Location"
        try context.save()

        XCTAssertEqual(child.logsArray.count, 1)
        XCTAssertEqual(child.logsArray.first?.wrappedLocation, "Test Location")
    }

    // MARK: - Supervisor

    func testCreateSupervisor() throws {
        let sup = Supervisor.create(in: context, name: "Jane Doe", relationship: "Foster Parent")
        try context.save()
        XCTAssertEqual(sup.wrappedName, "Jane Doe")
        XCTAssertEqual(sup.initials, "JD")
    }

    // MARK: - SupervisionLog

    func testLogDuration() throws {
        let child = Child.create(in: context, name: "Child", caseNumber: "001")
        let log = SupervisionLog.create(in: context, child: child, startTime: Date())
        log.endTime = Date().addingTimeInterval(7200)
        XCTAssertEqual(log.formattedDuration, "2h 0m")
    }

    func testLogSubmit() throws {
        let child = Child.create(in: context, name: "Child", caseNumber: "001")
        let log = SupervisionLog.create(in: context, child: child, startTime: Date())
        XCTAssertFalse(log.isSubmitted)
        log.submit(by: "Test User")
        XCTAssertTrue(log.isSubmitted)
        XCTAssertEqual(log.wrappedSubmittedBy, "Test User")
        XCTAssertNotNil(log.submittedAt)
    }

    func testLogFlagged() throws {
        let child = Child.create(in: context, name: "Child", caseNumber: "001")
        let log = SupervisionLog.create(in: context, child: child, startTime: Date())
        log.isFlagged = true
        log.flagReason = "Concerning behavior"
        try context.save()

        XCTAssertEqual(child.flaggedLogsCount, 1)
        XCTAssertEqual(log.wrappedFlagReason, "Concerning behavior")
    }

    // MARK: - Incident

    func testCreateIncident() throws {
        let child = Child.create(in: context, name: "Child", caseNumber: "001")
        let log = SupervisionLog.create(in: context, child: child, startTime: Date())
        let incident = Incident.create(
            in: context,
            log: log,
            type: Constants.IncidentType.medical.rawValue,
            description: "Headache reported",
            severity: Constants.IncidentSeverity.low.rawValue,
            reportedBy: "Jane"
        )
        try context.save()

        XCTAssertEqual(log.incidentsArray.count, 1)
        XCTAssertEqual(incident.wrappedType, "Medical")
        XCTAssertEqual(incident.wrappedSeverity, "Low")
    }

    // MARK: - Export

    func testPDFExportProduceData() throws {
        let child = Child.create(in: context, name: "Export Child", caseNumber: "EXP-001")
        let log = SupervisionLog.create(in: context, child: child, startTime: Date())
        log.endTime = Date().addingTimeInterval(3600)
        log.location = "Test Home"
        log.activities = "Test activities"
        log.status = Constants.LogStatus.submitted.rawValue
        try context.save()

        let export = ExportService.generatePDF(for: log)
        XCTAssertNotNil(export)
        XCTAssertFalse(export!.data.isEmpty)
    }
}
