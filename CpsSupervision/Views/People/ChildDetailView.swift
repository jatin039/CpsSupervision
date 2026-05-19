import SwiftUI

struct ChildListView: View {
    @Environment(\.managedObjectContext) private var ctx
    @FetchRequest(sortDescriptors: [SortDescriptor(\Child.name)], animation: .default)
    private var children: FetchedResults<Child>
    @State private var showAdd = false

    var body: some View {
        Group {
            if children.isEmpty {
                ContentUnavailableView(
                    "No Children Added",
                    systemImage: "person.badge.plus",
                    description: Text("Add a child profile to start logging supervision sessions.")
                )
                .overlay(alignment: .bottom) {
                    Button { showAdd = true } label: {
                        Label("Add Child", systemImage: "plus")
                            .padding().frame(maxWidth: 200)
                            .background(.blue).foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.bottom, 40)
                }
            } else {
                List {
                    ForEach(children) { child in
                        NavigationLink(destination: ChildDetailView(child: child)) {
                            ChildRowView(child: child)
                        }
                    }
                    .onDelete { indexSet in
                        indexSet.map { children[$0] }.forEach { PersistenceController.shared.delete($0) }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAdd = true } label: {
                    Image(systemName: "plus.circle.fill").font(.title2)
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddChildView()
        }
    }
}

private struct ChildRowView: View {
    @ObservedObject var child: Child
    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let img = child.photo {
                    Image(uiImage: img).resizable().scaledToFill()
                } else {
                    Color.blue.opacity(0.12)
                        .overlay(Text(String(child.wrappedName.prefix(1)))
                            .font(.headline.bold()).foregroundStyle(.blue))
                }
            }
            .frame(width: 44, height: 44).clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(child.wrappedName).font(.headline)
                Text(child.wrappedCaseNumber).font(.caption).foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    Label("\(child.logsArray.count) sessions", systemImage: "calendar")
                    if child.flaggedLogsCount > 0 {
                        Label("\(child.flaggedLogsCount) flagged", systemImage: "flag.fill")
                            .foregroundStyle(.orange)
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

struct ChildDetailView: View {
    @ObservedObject var child: Child
    @EnvironmentObject var sharingService: SharingService
    @State private var showEdit = false
    @State private var showShareSheet = false
    @State private var showNewLog = false
    @State private var exportedPDF: PDFExport?
    @State private var showExportShare = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                profileHeader
                statsRow
                if !child.wrappedCaseWorkerName.isEmpty { caseWorkerCard }
                if !child.wrappedNotes.isEmpty { notesCard }
                logsSection
            }
            .padding()
        }
        .navigationTitle(child.wrappedName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button { showEdit = true } label: { Label("Edit Profile", systemImage: "pencil") }
                    Button { showNewLog = true } label: { Label("New Session", systemImage: "plus.circle") }
                    Divider()
                    Button { shareAccess() } label: { Label("Share Access", systemImage: "person.badge.plus") }
                    Button { exportChildLogs() } label: { Label("Export All Logs", systemImage: "arrow.down.doc") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEdit) { AddChildView(editingChild: child) }
        .sheet(isPresented: $showNewLog) { NewLogEntryView() }
        .sheet(isPresented: $showShareSheet) {
            if let share = sharingService.activeShare,
               let container = sharingService.activeContainer {
                CloudSharingSheet(share: share, container: container) {
                    sharingService.activeShare = nil
                }
            }
        }
        .sheet(isPresented: $showExportShare) {
            if let pdf = exportedPDF {
                ShareLink(item: pdf, preview: SharePreview(pdf.filename, image: Image(systemName: "doc.richtext")))
                    .presentationDetents([.medium])
            }
        }
        .onChange(of: sharingService.activeShare) {
            if sharingService.activeShare != nil { showShareSheet = true }
        }
    }

    private var profileHeader: some View {
        HStack(spacing: 16) {
            Group {
                if let img = child.photo {
                    Image(uiImage: img).resizable().scaledToFill()
                } else {
                    Color.blue.opacity(0.12)
                        .overlay(Text(String(child.wrappedName.prefix(1)))
                            .font(.system(size: 36, weight: .bold)).foregroundStyle(.blue))
                }
            }
            .frame(width: 80, height: 80).clipShape(Circle())
            .overlay(Circle().strokeBorder(Color.blue.opacity(0.2), lineWidth: 2))

            VStack(alignment: .leading, spacing: 4) {
                Text(child.wrappedName).font(.title2.bold())
                Text("Case: \(child.wrappedCaseNumber)").font(.subheadline).foregroundStyle(.secondary)
                if child.dateOfBirth != nil {
                    Text(child.age).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            MiniStatCard(value: "\(child.logsArray.count)", label: "Total Sessions", color: .blue)
            MiniStatCard(value: String(format: "%.1f", child.totalHoursThisMonth), label: "Hours (month)", color: .green)
            MiniStatCard(value: "\(child.flaggedLogsCount)", label: "Flagged", color: child.flaggedLogsCount > 0 ? .orange : .gray)
        }
    }

    private var caseWorkerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Case Worker", systemImage: "person.text.rectangle").font(.subheadline.bold()).foregroundStyle(.purple)
            Text(child.wrappedCaseWorkerName).font(.body)
            if !child.wrappedCaseWorkerPhone.isEmpty {
                Link(child.wrappedCaseWorkerPhone, destination: URL(string: "tel:\(child.wrappedCaseWorkerPhone)")!)
                    .font(.body)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Notes", systemImage: "note.text").font(.subheadline.bold()).foregroundStyle(.secondary)
            Text(child.wrappedNotes).font(.body)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private var logsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Session History").font(.headline)
                Spacer()
                Button { showNewLog = true } label: {
                    Image(systemName: "plus.circle").foregroundStyle(.blue)
                }
            }
            if child.logsArray.isEmpty {
                Text("No sessions logged yet.").font(.subheadline).foregroundStyle(.secondary).padding(.top, 4)
            } else {
                ForEach(child.logsArray.prefix(20)) { log in
                    NavigationLink(destination: LogDetailView(log: log)) {
                        LogRowView(log: log)
                            .padding()
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func shareAccess() {
        Task { await sharingService.share(child: child) }
    }

    private func exportChildLogs() {
        let logs = child.logsArray
        if let pdf = ExportService.generatePDF(for: logs, child: child) {
            exportedPDF = pdf
            showExportShare = true
        }
    }
}

private struct MiniStatCard: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 22, weight: .bold, design: .rounded)).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
