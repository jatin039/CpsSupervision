import SwiftUI
import CoreData

struct DashboardView: View {
    @Environment(\.managedObjectContext) private var ctx
    @StateObject private var viewModel: DashboardViewModel
    @State private var showNewLog = false

    @FetchRequest(
        sortDescriptors: [SortDescriptor(\SupervisionLog.startTime, order: .reverse)],
        predicate: nil,
        animation: .default
    )
    private var recentLogs: FetchedResults<SupervisionLog>

    @FetchRequest(
        sortDescriptors: [SortDescriptor(\Child.name)],
        animation: .default
    )
    private var children: FetchedResults<Child>

    init() {
        _viewModel = StateObject(wrappedValue: DashboardViewModel(context: PersistenceController.shared.container.viewContext))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    greetingHeader
                    statsCards
                    if !children.isEmpty {
                        recentLogsSection
                    } else {
                        emptyState
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showNewLog = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .disabled(children.isEmpty)
                }
            }
            .sheet(isPresented: $showNewLog) {
                NewLogEntryView()
            }
        }
    }

    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Date().monthYearString)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .kerning(1)
        }
    }

    private var statsCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(
                title: "Sessions",
                value: "\(viewModel.logsThisMonth)",
                subtitle: "this month",
                icon: "calendar.badge.checkmark",
                color: .blue
            )
            StatCard(
                title: "Hours",
                value: String(format: "%.1f", viewModel.hoursThisMonth),
                subtitle: "logged this month",
                icon: "clock.fill",
                color: .green
            )
            StatCard(
                title: "Flagged",
                value: "\(viewModel.flaggedCount)",
                subtitle: "concern items",
                icon: "flag.fill",
                color: viewModel.flaggedCount > 0 ? .orange : .gray
            )
            StatCard(
                title: "Children",
                value: "\(viewModel.childrenActiveThisMonth)",
                subtitle: "supervised this month",
                icon: "person.fill",
                color: .purple
            )
        }
    }

    private var recentLogsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Sessions")
                .font(.headline)

            ForEach(Array(recentLogs.prefix(5))) { log in
                NavigationLink(destination: LogDetailView(log: log)) {
                    LogRowView(log: log)
                }
                .buttonStyle(.plain)
            }

            if recentLogs.isEmpty {
                ContentUnavailableView(
                    "No sessions yet",
                    systemImage: "list.bullet.clipboard",
                    description: Text("Tap + to log a supervision session")
                )
                .frame(height: 160)
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "Get Started",
            systemImage: "person.badge.plus",
            description: Text("Add a child profile in the People tab to start logging supervision sessions")
        )
        .frame(height: 240)
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Spacer()
            }
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(color.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    DashboardView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(PersistenceController.preview)
}
