import SwiftUI

struct LogDetailView: View {
    @ObservedObject var log: SupervisionLog
    @Environment(\.managedObjectContext) private var ctx
    @AppStorage(Constants.UserDefaultsKey.currentUserName) private var currentUserName = ""

    @State private var showEdit = false
    @State private var exportedPDF: PDFExport?
    @State private var showShareSheet = false
    @State private var showSubmitConfirm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerCard
                sessionDetails
                supervisorsSection
                activitiesSection
                if !log.wrappedNotes.isEmpty { notesSection }
                if log.isFlagged == true { flagSection }
                if !log.incidentsArray.isEmpty { incidentsSection }
                actionButtons
            }
            .padding()
        }
        .navigationTitle(log.startTime?.shortDateString ?? "Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showEdit = true } label: {
                    Text("Edit")
                }
                .disabled(log.isSubmitted)
            }
        }
        .sheet(isPresented: $showEdit) {
            NewLogEntryView(editingLog: log)
        }
        .sheet(isPresented: $showShareSheet) {
            if let pdf = exportedPDF {
                ShareLink(
                    item: pdf,
                    preview: SharePreview(pdf.filename, image: Image(systemName: "doc.richtext.fill"))
                )
                .presentationDetents([.medium])
            }
        }
        .confirmationDialog("Submit this session log?", isPresented: $showSubmitConfirm, titleVisibility: .visible) {
            Button("Submit") { submitLog() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Once submitted, this log cannot be edited.")
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading) {
                    Text(log.child?.wrappedName ?? "Unknown Child")
                        .font(.title2.bold())
                    Text(log.child?.wrappedCaseNumber ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                StatusBadge(status: log.wrappedStatus)
            }

            Divider()

            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Date").font(.caption).foregroundStyle(.secondary)
                    Text(log.startTime?.shortDateString ?? "–").font(.subheadline.bold())
                }
                VStack(alignment: .leading) {
                    Text("Duration").font(.caption).foregroundStyle(.secondary)
                    Text(log.formattedDuration).font(.subheadline.bold())
                }
                VStack(alignment: .leading) {
                    Text("Time").font(.caption).foregroundStyle(.secondary)
                    Text(log.dateRangeString).font(.subheadline.bold())
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private var sessionDetails: some View {
        DetailSection(title: "Location", icon: "mappin.and.ellipse", iconColor: .red) {
            VStack(alignment: .leading, spacing: 4) {
                Text(log.wrappedLocation).font(.body)
                if !log.wrappedLocationType.isEmpty {
                    Text(log.wrappedLocationType).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    private var supervisorsSection: some View {
        DetailSection(title: "Supervisors Present (\(log.supervisorsArray.count))",
                      icon: "person.2.fill", iconColor: .blue) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(log.supervisorsArray) { sup in
                    HStack {
                        Circle()
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 32, height: 32)
                            .overlay(Text(sup.initials).font(.caption.bold()).foregroundStyle(.blue))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(sup.wrappedName).font(.subheadline.bold())
                            Text([sup.wrappedRelationship, sup.wrappedPhone]
                                .filter { !$0.isEmpty }.joined(separator: " · "))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var activitiesSection: some View {
        DetailSection(title: "Activities", icon: "list.star", iconColor: .green) {
            Text(log.wrappedActivities.isEmpty ? "None recorded" : log.wrappedActivities)
                .font(.body)
                .foregroundStyle(log.wrappedActivities.isEmpty ? .secondary : .primary)
        }
    }

    private var notesSection: some View {
        DetailSection(title: "Notes", icon: "note.text", iconColor: .purple) {
            Text(log.wrappedNotes).font(.body)
        }
    }

    private var flagSection: some View {
        DetailSection(title: "Concern Flagged", icon: "flag.fill", iconColor: .orange) {
            VStack(alignment: .leading, spacing: 4) {
                Text(log.wrappedFlagReason.isEmpty ? "Flagged without specific reason" : log.wrappedFlagReason)
                    .font(.body)
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.orange.opacity(0.4), lineWidth: 1))
    }

    private var incidentsSection: some View {
        DetailSection(title: "Incidents (\(log.incidentsArray.count))", icon: "exclamationmark.triangle.fill", iconColor: .red) {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(log.incidentsArray) { incident in
                    IncidentRowView(incident: incident)
                }
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.red.opacity(0.3), lineWidth: 1))
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if !log.isSubmitted {
                Button {
                    showSubmitConfirm = true
                } label: {
                    Label("Submit Log", systemImage: "paperplane.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }

            Button {
                exportLog()
            } label: {
                Label("Export as PDF", systemImage: "arrow.down.doc")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(.top, 8)
    }

    private func submitLog() {
        log.submit(by: currentUserName.isEmpty ? "Unknown User" : currentUserName)
        PersistenceController.shared.save()
    }

    private func exportLog() {
        if let pdf = ExportService.generatePDF(for: log) {
            exportedPDF = pdf
            showShareSheet = true
        }
    }
}

private struct DetailSection<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.subheadline.bold())
                .foregroundStyle(iconColor)
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct IncidentRowView: View {
    let incident: Incident
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(incident.wrappedType).font(.subheadline.bold())
                Spacer()
                Text(incident.wrappedSeverity)
                    .font(.caption.bold())
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.forSeverity(incident.wrappedSeverity).opacity(0.15))
                    .foregroundStyle(Color.forSeverity(incident.wrappedSeverity))
                    .clipShape(Capsule())
            }
            Text(incident.wrappedDescription).font(.body)
            if !incident.wrappedActionTaken.isEmpty {
                Text("Action: \(incident.wrappedActionTaken)")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Text("Reported by \(incident.wrappedReportedBy)")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(10)
        .background(Color.forSeverity(incident.wrappedSeverity).opacity(0.06),
                    in: RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    NavigationStack {
        LogDetailView(log: PersistenceController.preview.container.viewContext
            .registeredObjects.compactMap { $0 as? SupervisionLog }.first!)
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
