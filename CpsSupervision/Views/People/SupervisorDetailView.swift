import SwiftUI

struct SupervisorListView: View {
    @Environment(\.managedObjectContext) private var ctx
    @FetchRequest(sortDescriptors: [SortDescriptor(\Supervisor.name)], animation: .default)
    private var supervisors: FetchedResults<Supervisor>
    @State private var showAdd = false

    var body: some View {
        Group {
            if supervisors.isEmpty {
                ContentUnavailableView(
                    "No Supervisors Added",
                    systemImage: "person.badge.plus",
                    description: Text("Add supervisors who participate in sessions.")
                )
                .overlay(alignment: .bottom) {
                    Button { showAdd = true } label: {
                        Label("Add Supervisor", systemImage: "plus")
                            .padding().frame(maxWidth: 220)
                            .background(.blue).foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.bottom, 40)
                }
            } else {
                List {
                    ForEach(supervisors) { sup in
                        NavigationLink(destination: SupervisorDetailView(supervisor: sup)) {
                            SupervisorRowView(supervisor: sup)
                        }
                    }
                    .onDelete { indexSet in
                        indexSet.map { supervisors[$0] }.forEach { PersistenceController.shared.delete($0) }
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
            AddSupervisorView()
        }
    }
}

private struct SupervisorRowView: View {
    @ObservedObject var supervisor: Supervisor
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.blue.opacity(0.12))
                .frame(width: 44, height: 44)
                .overlay(Text(supervisor.initials).font(.headline.bold()).foregroundStyle(.blue))

            VStack(alignment: .leading, spacing: 3) {
                Text(supervisor.wrappedName).font(.headline)
                Text(supervisor.wrappedRelationship).font(.caption).foregroundStyle(.secondary)
                Label("\(supervisor.totalSessionsCount) sessions · \(String(format: "%.1f", supervisor.totalHoursLogged))h",
                      systemImage: "calendar")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

struct SupervisorDetailView: View {
    @ObservedObject var supervisor: Supervisor
    @State private var showEdit = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                profileHeader
                contactCard
                statsRow
                recentLogsSection
            }
            .padding()
        }
        .navigationTitle(supervisor.wrappedName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showEdit = true } label: { Text("Edit") }
            }
        }
        .sheet(isPresented: $showEdit) {
            AddSupervisorView(editingSupervisor: supervisor)
        }
    }

    private var profileHeader: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.blue.opacity(0.12))
                .frame(width: 80, height: 80)
                .overlay(Text(supervisor.initials)
                    .font(.system(size: 32, weight: .bold)).foregroundStyle(.blue))
                .overlay(Circle().strokeBorder(Color.blue.opacity(0.2), lineWidth: 2))

            VStack(alignment: .leading, spacing: 4) {
                Text(supervisor.wrappedName).font(.title2.bold())
                Text(supervisor.wrappedRelationship).font(.subheadline).foregroundStyle(.secondary)
                if !supervisor.wrappedOrganization.isEmpty {
                    Text(supervisor.wrappedOrganization).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
    }

    private var contactCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Contact", systemImage: "person.crop.square").font(.subheadline.bold()).foregroundStyle(.blue)
            if !supervisor.wrappedPhone.isEmpty {
                Link(destination: URL(string: "tel:\(supervisor.wrappedPhone)")!) {
                    Label(supervisor.wrappedPhone, systemImage: "phone.fill")
                        .font(.body)
                }
            }
            if !supervisor.wrappedEmail.isEmpty {
                Link(destination: URL(string: "mailto:\(supervisor.wrappedEmail)")!) {
                    Label(supervisor.wrappedEmail, systemImage: "envelope.fill")
                        .font(.body)
                }
            }
            if supervisor.wrappedPhone.isEmpty && supervisor.wrappedEmail.isEmpty {
                Text("No contact info recorded").foregroundStyle(.secondary).font(.subheadline)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            MiniStat(value: "\(supervisor.totalSessionsCount)", label: "Sessions")
            MiniStat(value: String(format: "%.1f", supervisor.totalHoursLogged), label: "Hours Total")
        }
    }

    private var recentLogsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Sessions").font(.headline)
            if supervisor.logsArray.isEmpty {
                Text("No sessions recorded yet.").font(.subheadline).foregroundStyle(.secondary)
            } else {
                ForEach(supervisor.logsArray.prefix(10)) { log in
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

    private struct MiniStat: View {
        let value: String
        let label: String
        var body: some View {
            VStack(spacing: 4) {
                Text(value).font(.system(size: 22, weight: .bold, design: .rounded)).foregroundStyle(.blue)
                Text(label).font(.caption2).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(10)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    NavigationStack {
        SupervisorDetailView(
            supervisor: PersistenceController.preview.container.viewContext
                .registeredObjects.compactMap { $0 as? Supervisor }.first!
        )
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
