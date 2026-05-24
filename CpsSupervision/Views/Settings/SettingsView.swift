import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var biometricService: BiometricService
    @AppStorage(Constants.UserDefaultsKey.currentUserName) private var currentUserName = ""
    @AppStorage(Constants.UserDefaultsKey.exportIncludePhotos) private var exportIncludePhotos = true

    @FetchRequest(sortDescriptors: [SortDescriptor(\SupervisionLog.startTime, order: .reverse)])
    private var allLogs: FetchedResults<SupervisionLog>

    @State private var showExportAll = false
    @State private var exportedPDF: PDFExport?
    @State private var showShareSheet = false

    var body: some View {
        NavigationStack {
            Form {
                userSection
                securitySection
                exportSection
                syncSection
                aboutSection
            }
            .navigationTitle("Settings")
        }
        .sheet(isPresented: $showShareSheet) {
            if let pdf = exportedPDF {
                ShareLink(
                    item: pdf,
                    preview: SharePreview(pdf.filename, image: Image(systemName: "doc.fill"))
                )
                .presentationDetents([.medium])
            }
        }
    }

    private var userSection: some View {
        Section("Your Profile") {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
                TextField("Your name (appears on logs)", text: $currentUserName)
            }
        }
    }

    private var securitySection: some View {
        Section {
            HStack {
                Label(biometricService.biometricName, systemImage: biometricService.biometricSystemImageName)
                Spacer()
                Text("Always On")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
        } header: {
            Text("Security")
        } footer: {
            Text("\(biometricService.biometricName) is required every time the app opens or returns from the background to protect sensitive records.")
        }
    }

    private var exportSection: some View {
        Section {
            Toggle("Include photos in exports", isOn: $exportIncludePhotos)

            Button {
                exportAllLogs()
            } label: {
                Label("Export All Logs as PDF", systemImage: "arrow.down.doc.fill")
            }
            .disabled(allLogs.isEmpty)
        } header: {
            Text("Export")
        } footer: {
            Text("Exports a formatted PDF suitable for court or case worker submission.")
        }
    }

    private var syncSection: some View {
        Section {
            LabeledContent("Sync Method") {
                Text("iCloud (CloudKit)")
                    .foregroundStyle(.secondary)
            }
            LabeledContent("Container") {
                Text(Constants.cloudKitContainerID)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Sync & Sharing")
        } footer: {
            Text("To share access with co-supervisors, open a child's profile and tap \"Share Access\".")
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: "1.0.0")
            LabeledContent("Total Sessions Logged", value: "\(allLogs.count)")
            Link(destination: URL(string: "https://www.acf.hhs.gov/cb")!) {
                Label("Child Welfare Information Gateway", systemImage: "link")
            }
        }
    }

    private func exportAllLogs() {
        let logs = Array(allLogs)
        if let pdf = ExportService.generatePDF(for: logs) {
            exportedPDF = pdf
            showShareSheet = true
        }
    }
}

#Preview {
    SettingsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(BiometricService())
}
