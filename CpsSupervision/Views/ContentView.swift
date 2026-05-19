import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var persistenceController: PersistenceController

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "house.fill") }
                .tag(0)

            LogListView()
                .tabItem { Label("Logs", systemImage: "list.bullet.clipboard.fill") }
                .tag(1)

            PeopleView()
                .tabItem { Label("People", systemImage: "person.2.fill") }
                .tag(2)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(3)
        }
        .overlay(alignment: .topTrailing) {
            SyncStatusBadge(status: persistenceController.syncStatus)
                .padding(.top, 8)
                .padding(.trailing, 16)
        }
    }
}

private struct SyncStatusBadge: View {
    let status: PersistenceController.SyncStatus

    var body: some View {
        Group {
            switch status {
            case .syncing:
                HStack(spacing: 4) {
                    ProgressView().scaleEffect(0.7)
                    Text("Syncing").font(.caption2)
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(.regularMaterial, in: Capsule())
            case .error:
                Label("Sync error", systemImage: "exclamationmark.icloud")
                    .font(.caption2).foregroundStyle(.red)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(.regularMaterial, in: Capsule())
            default:
                EmptyView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(BiometricService())
        .environmentObject(SharingService.shared)
        .environmentObject(PersistenceController.preview)
}
