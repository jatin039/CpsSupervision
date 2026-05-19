import SwiftUI
import CoreData

struct NewLogEntryView: View {
    @Environment(\.managedObjectContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @AppStorage(Constants.UserDefaultsKey.currentUserName) private var currentUserName = ""

    var editingLog: SupervisionLog?

    @FetchRequest(sortDescriptors: [SortDescriptor(\Child.name)])
    private var children: FetchedResults<Child>

    @FetchRequest(sortDescriptors: [SortDescriptor(\Supervisor.name)])
    private var allSupervisors: FetchedResults<Supervisor>

    // Form state
    @State private var selectedChild: Child?
    @State private var startTime = Date()
    @State private var endTime = Date().addingTimeInterval(3600)
    @State private var hasEndTime = true
    @State private var location = ""
    @State private var locationType = Constants.LocationType.home
    @State private var selectedSupervisors: Set<NSManagedObjectID> = []
    @State private var activities = ""
    @State private var notes = ""
    @State private var isFlagged = false
    @State private var flagReason = ""
    @State private var status = Constants.LogStatus.draft
    @State private var incidents: [IncidentDraft] = []

    @State private var showSupervisorPicker = false
    @State private var showIncidentForm = false
    @State private var editingIncident: IncidentDraft?
    @State private var showValidationAlert = false
    @State private var validationMessage = ""

    private var isEditing: Bool { editingLog != nil }

    var body: some View {
        NavigationStack {
            Form {
                childSection
                sessionSection
                locationSection
                supervisorsSection
                activitiesSection
                concernsSection
                incidentsSection
                statusSection
            }
            .navigationTitle(isEditing ? "Edit Session" : "New Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Save") {
                        saveLog()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showSupervisorPicker) {
                SupervisorPickerView(
                    allSupervisors: Array(allSupervisors),
                    selected: $selectedSupervisors
                )
            }
            .sheet(isPresented: $showIncidentForm) {
                IncidentFormView(editingDraft: editingIncident) { draft in
                    if let existing = editingIncident,
                       let index = incidents.firstIndex(where: { $0.id == existing.id }) {
                        incidents[index] = draft
                    } else {
                        incidents.append(draft)
                    }
                    editingIncident = nil
                }
            }
            .alert("Required Fields", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(validationMessage)
            }
        }
        .onAppear { populateFromEditingLog() }
    }

    private var childSection: some View {
        Section("Child") {
            if children.isEmpty {
                Text("No children added yet. Add one in the People tab.")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            } else {
                Picker("Child", selection: $selectedChild) {
                    Text("Select a child").tag(nil as Child?)
                    ForEach(children) { child in
                        Text(child.wrappedName).tag(child as Child?)
                    }
                }
            }
        }
    }

    private var sessionSection: some View {
        Section("Session Time") {
            DatePicker("Start", selection: $startTime)
            Toggle("Record end time", isOn: $hasEndTime)
            if hasEndTime {
                DatePicker("End", selection: $endTime, in: startTime...)
            }
        }
    }

    private var locationSection: some View {
        Section("Location") {
            TextField("Location name or address", text: $location)
            Picker("Type", selection: $locationType) {
                ForEach(Constants.LocationType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
        }
    }

    private var supervisorsSection: some View {
        Section {
            let selected = allSupervisors.filter { selectedSupervisors.contains($0.objectID) }
            if selected.isEmpty {
                Button { showSupervisorPicker = true } label: {
                    Label("Add supervisors present", systemImage: "person.badge.plus")
                }
            } else {
                ForEach(selected) { sup in
                    HStack {
                        Circle()
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 32, height: 32)
                            .overlay(Text(sup.initials).font(.caption.bold()).foregroundStyle(.blue))
                        Text(sup.wrappedName)
                    }
                }
                .onDelete { indexSet in
                    let idsToRemove = indexSet.map { selected[$0].objectID }
                    selectedSupervisors.subtract(idsToRemove)
                }
                Button { showSupervisorPicker = true } label: {
                    Label("Edit supervisors", systemImage: "pencil")
                        .font(.caption)
                }
            }
        } header: {
            Text("Supervisors Present")
        }
    }

    private var activitiesSection: some View {
        Section("Activities & Notes") {
            ZStack(alignment: .topLeading) {
                if activities.isEmpty {
                    Text("Describe activities during this session...")
                        .foregroundStyle(.tertiary)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                }
                TextEditor(text: $activities)
                    .frame(minHeight: 80)
            }
            ZStack(alignment: .topLeading) {
                if notes.isEmpty {
                    Text("Additional notes (optional)...")
                        .foregroundStyle(.tertiary)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                }
                TextEditor(text: $notes)
                    .frame(minHeight: 60)
            }
        }
    }

    private var concernsSection: some View {
        Section {
            Toggle(isOn: $isFlagged) {
                Label("Flag a concern", systemImage: "flag")
                    .foregroundStyle(isFlagged ? .orange : .primary)
            }
            if isFlagged {
                TextField("Describe the concern...", text: $flagReason, axis: .vertical)
                    .lineLimit(3...6)
            }
        } header: {
            Text("Concerns")
        } footer: {
            if isFlagged {
                Text("Flagged logs are highlighted and included in concern reports.")
            }
        }
    }

    private var incidentsSection: some View {
        Section {
            ForEach(incidents) { incident in
                Button {
                    editingIncident = incident
                    showIncidentForm = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(incident.type).font(.subheadline.bold())
                            Text(incident.description).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                        }
                        Spacer()
                        Text(incident.severity)
                            .font(.caption2.bold())
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color.forSeverity(incident.severity).opacity(0.15))
                            .foregroundStyle(Color.forSeverity(incident.severity))
                            .clipShape(Capsule())
                    }
                }
                .buttonStyle(.plain)
            }
            .onDelete { incidents.remove(atOffsets: $0) }

            Button {
                editingIncident = nil
                showIncidentForm = true
            } label: {
                Label("Add incident", systemImage: "plus")
            }
        } header: {
            Text("Incidents")
        } footer: {
            Text("Document any concerns, behavioral events, or safety issues.")
        }
    }

    private var statusSection: some View {
        Section("Status") {
            Picker("Status", selection: $status) {
                ForEach(Constants.LogStatus.allCases, id: \.self) { s in
                    Text(s.displayName).tag(s)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private func populateFromEditingLog() {
        guard let log = editingLog else {
            if children.count == 1 { selectedChild = children.first }
            return
        }
        selectedChild = log.child
        startTime = log.startTime ?? Date()
        if let end = log.endTime {
            endTime = end
            hasEndTime = true
        } else {
            hasEndTime = false
        }
        location = log.wrappedLocation
        locationType = Constants.LocationType(rawValue: log.wrappedLocationType) ?? .home
        selectedSupervisors = Set(log.supervisorsArray.map { $0.objectID })
        activities = log.wrappedActivities
        notes = log.wrappedNotes
        isFlagged = log.isFlagged == true
        flagReason = log.wrappedFlagReason
        status = Constants.LogStatus(rawValue: log.wrappedStatus) ?? .draft
        incidents = log.incidentsArray.map { IncidentDraft(from: $0) }
    }

    private func saveLog() {
        guard validate() else { return }

        let log = editingLog ?? SupervisionLog(context: ctx)
        if editingLog == nil {
            log.id = UUID()
            log.createdAt = Date()
        }

        log.child = selectedChild
        log.startTime = startTime
        log.endTime = hasEndTime ? endTime : nil
        log.location = location
        log.locationType = locationType.rawValue
        log.activities = activities
        log.notes = notes
        log.isFlagged = isFlagged
        log.flagReason = isFlagged ? flagReason : nil
        log.status = status.rawValue
        log.updatedAt = Date()

        if status == .submitted && log.submittedAt == nil {
            log.submittedAt = Date()
            log.submittedBy = currentUserName.isEmpty ? "Unknown" : currentUserName
        }

        let supervisorObjects = selectedSupervisors.compactMap {
            try? ctx.existingObject(with: $0) as? Supervisor
        }
        log.supervisors = NSSet(array: supervisorObjects)

        // Sync incidents
        let existingIncidents = log.incidentsArray
        let draftIDs = Set(incidents.compactMap { $0.existingObjectID })
        for existing in existingIncidents where !draftIDs.contains(existing.objectID) {
            ctx.delete(existing)
        }
        for draft in incidents {
            if let existingID = draft.existingObjectID,
               let incident = try? ctx.existingObject(with: existingID) as? Incident {
                incident.type = draft.type
                incident.incidentDescription = draft.description
                incident.severity = draft.severity
                incident.reportedBy = draft.reportedBy
                incident.actionTaken = draft.actionTaken
            } else {
                let incident = Incident(context: ctx)
                incident.id = UUID()
                incident.log = log
                incident.type = draft.type
                incident.incidentDescription = draft.description
                incident.severity = draft.severity
                incident.reportedBy = draft.reportedBy.isEmpty ? (currentUserName.isEmpty ? "Unknown" : currentUserName) : draft.reportedBy
                incident.actionTaken = draft.actionTaken
                incident.reportedAt = Date()
            }
        }

        PersistenceController.shared.save()
        dismiss()
    }

    private func validate() -> Bool {
        if selectedChild == nil {
            validationMessage = "Please select a child for this session."
            showValidationAlert = true
            return false
        }
        if location.trimmingCharacters(in: .whitespaces).isEmpty {
            validationMessage = "Please enter a location for this session."
            showValidationAlert = true
            return false
        }
        return true
    }
}

struct IncidentDraft: Identifiable {
    var id = UUID()
    var type = Constants.IncidentType.other.rawValue
    var description = ""
    var severity = Constants.IncidentSeverity.low.rawValue
    var reportedBy = ""
    var actionTaken = ""
    var existingObjectID: NSManagedObjectID?

    init() {}

    init(from incident: Incident) {
        self.id = incident.id ?? UUID()
        self.type = incident.wrappedType
        self.description = incident.wrappedDescription
        self.severity = incident.wrappedSeverity
        self.reportedBy = incident.wrappedReportedBy
        self.actionTaken = incident.wrappedActionTaken
        self.existingObjectID = incident.objectID
    }
}

private struct SupervisorPickerView: View {
    let allSupervisors: [Supervisor]
    @Binding var selected: Set<NSManagedObjectID>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(allSupervisors) { sup in
                Button {
                    if selected.contains(sup.objectID) {
                        selected.remove(sup.objectID)
                    } else {
                        selected.insert(sup.objectID)
                    }
                } label: {
                    HStack {
                        Circle()
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 36, height: 36)
                            .overlay(Text(sup.initials).font(.subheadline.bold()).foregroundStyle(.blue))
                        VStack(alignment: .leading) {
                            Text(sup.wrappedName).font(.body).foregroundStyle(.primary)
                            Text(sup.wrappedRelationship).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if selected.contains(sup.objectID) {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Select Supervisors")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct IncidentFormView: View {
    @Environment(\.dismiss) private var dismiss
    var editingDraft: IncidentDraft?
    var onSave: (IncidentDraft) -> Void

    @State private var draft = IncidentDraft()

    var body: some View {
        NavigationStack {
            Form {
                Section("Incident Details") {
                    Picker("Type", selection: $draft.type) {
                        ForEach(Constants.IncidentType.allCases, id: \.rawValue) { type in
                            Text(type.rawValue).tag(type.rawValue)
                        }
                    }
                    Picker("Severity", selection: $draft.severity) {
                        ForEach(Constants.IncidentSeverity.allCases, id: \.rawValue) { sev in
                            Text(sev.rawValue).tag(sev.rawValue)
                        }
                    }
                }
                Section("Description") {
                    TextEditor(text: $draft.description)
                        .frame(minHeight: 80)
                }
                Section("Response") {
                    TextField("Reported by", text: $draft.reportedBy)
                    TextField("Action taken (optional)", text: $draft.actionTaken, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle(editingDraft == nil ? "Add Incident" : "Edit Incident")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(draft)
                        dismiss()
                    }
                    .disabled(draft.description.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .onAppear {
            if let existing = editingDraft { draft = existing }
        }
    }
}

#Preview {
    NewLogEntryView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
