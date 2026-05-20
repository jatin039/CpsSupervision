import SwiftUI
import CoreData

struct LogListView: View {
    @Environment(\.managedObjectContext) private var ctx
    @StateObject private var viewModel = LogsViewModel()
    @State private var showNewLog = false
    @State private var showFilters = false

    @FetchRequest(
        sortDescriptors: [SortDescriptor(\SupervisionLog.startTime, order: .reverse)],
        animation: .default
    )
    private var logs: FetchedResults<SupervisionLog>

    @FetchRequest(sortDescriptors: [SortDescriptor(\Child.name)])
    private var children: FetchedResults<Child>

    private var filteredLogs: [SupervisionLog] {
        guard let predicate = viewModel.filterPredicate else { return Array(logs) }
        return logs.filter { predicate.evaluate(with: $0) }
    }

    private var groupedLogs: [(String, [SupervisionLog])] {
        let grouped = Dictionary(grouping: filteredLogs) { log -> String in
            log.startTime?.monthYearString ?? "Unknown Date"
        }
        return grouped.sorted { a, b in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            let dateA = formatter.date(from: a.key) ?? .distantPast
            let dateB = formatter.date(from: b.key) ?? .distantPast
            return dateA > dateB
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredLogs.isEmpty && viewModel.searchText.isEmpty && !viewModel.filterFlaggedOnly {
                    emptyState
                } else {
                    logsList
                }
            }
            .navigationTitle("Supervision Logs")
            .searchable(text: $viewModel.searchText, prompt: "Search logs...")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showNewLog = true } label: {
                        Image(systemName: "plus.circle.fill").font(.title2)
                    }
                    .disabled(children.isEmpty)
                }
                ToolbarItem(placement: .topBarLeading) {
                    filterMenu
                }
            }
            .sheet(isPresented: $showNewLog) {
                NewLogEntryView()
            }
        }
    }

    private var logsList: some View {
        List {
            ForEach(groupedLogs, id: \.0) { month, monthLogs in
                Section(month) {
                    ForEach(monthLogs) { log in
                        NavigationLink(destination: LogDetailView(log: log)) {
                            LogRowView(log: log)
                        }
                    }
                    .onDelete { indexSet in
                        indexSet.map { monthLogs[$0] }.forEach { viewModel.deleteLog($0) }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if filteredLogs.isEmpty {
                ContentUnavailableView.search(text: viewModel.searchText)
            }
        }
    }

    private var filterMenu: some View {
        Menu {
            Section("Status") {
                filterButton("All", value: "all", current: viewModel.filterStatus) {
                    viewModel.filterStatus = "all"
                }
                filterButton("Draft", value: Constants.LogStatus.draft.rawValue, current: viewModel.filterStatus) {
                    viewModel.filterStatus = Constants.LogStatus.draft.rawValue
                }
                filterButton("Submitted", value: Constants.LogStatus.submitted.rawValue, current: viewModel.filterStatus) {
                    viewModel.filterStatus = Constants.LogStatus.submitted.rawValue
                }
                filterButton("Reviewed", value: Constants.LogStatus.reviewed.rawValue, current: viewModel.filterStatus) {
                    viewModel.filterStatus = Constants.LogStatus.reviewed.rawValue
                }
            }
            Section("Concerns") {
                Toggle("Flagged only", isOn: $viewModel.filterFlaggedOnly)
            }
            if !children.isEmpty {
                Section("Child") {
                    Button { viewModel.selectedChildID = nil } label: {
                        HStack {
                            Text("All children")
                            if viewModel.selectedChildID == nil { Image(systemName: "checkmark") }
                        }
                    }
                    ForEach(children) { child in
                        Button { viewModel.selectedChildID = child.objectID } label: {
                            HStack {
                                Text(child.wrappedName)
                                if viewModel.selectedChildID == child.objectID { Image(systemName: "checkmark") }
                            }
                        }
                    }
                }
            }
        } label: {
            Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                .foregroundStyle(hasActiveFilters ? .blue : .primary)
        }
    }

    private func filterButton(_ title: String, value: String, current: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                if current == value { Image(systemName: "checkmark") }
            }
        }
    }

    private var hasActiveFilters: Bool {
        viewModel.filterStatus != "all" || viewModel.filterFlaggedOnly || viewModel.selectedChildID != nil
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No Logs Yet",
            systemImage: "list.bullet.clipboard",
            description: Text(children.isEmpty
                ? "Add a child in the People tab first, then log sessions here."
                : "Tap + to record your first supervision session.")
        )
    }
}

struct LogRowView: View {
    let log: SupervisionLog

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(log.child?.wrappedName ?? "Unknown Child")
                    .font(.headline)
                Spacer()
                StatusBadge(status: log.wrappedStatus)
                if log.isFlagged == true {
                    Image(systemName: "flag.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                }
            }
            HStack(spacing: 12) {
                Label(log.startTime?.shortDateString ?? "–", systemImage: "calendar")
                Label(log.dateRangeString, systemImage: "clock")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                Label(log.wrappedLocation, systemImage: "mappin.and.ellipse")
                if !log.supervisorsArray.isEmpty {
                    Label("\(log.supervisorsArray.count) supervisor\(log.supervisorsArray.count == 1 ? "" : "s")", systemImage: "person.2")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        .padding(.vertical, 2)
    }
}

struct StatusBadge: View {
    let status: String
    var body: some View {
        Text(status.capitalized)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.forStatus(status).opacity(0.15))
            .foregroundStyle(Color.forStatus(status))
            .clipShape(Capsule())
    }
}

#Preview {
    LogListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
