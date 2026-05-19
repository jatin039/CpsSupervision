import SwiftUI

struct PeopleView: View {
    @State private var segment = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Section", selection: $segment) {
                    Text("Children").tag(0)
                    Text("Supervisors").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemGroupedBackground))

                if segment == 0 {
                    ChildListView()
                } else {
                    SupervisorListView()
                }
            }
            .navigationTitle("People")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    PeopleView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(SharingService.shared)
}
