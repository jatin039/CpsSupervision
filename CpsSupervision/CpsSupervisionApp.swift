import SwiftUI

@main
struct CpsSupervisionApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var biometricService = BiometricService()
    @StateObject private var sharingService = SharingService.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if biometricService.isAuthEnabled && biometricService.isLocked {
                    LockView()
                        .environmentObject(biometricService)
                } else {
                    ContentView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                        .environmentObject(biometricService)
                        .environmentObject(sharingService)
                        .environmentObject(persistenceController)
                }
            }
            .onAppear {
                if biometricService.isAuthEnabled && biometricService.isLocked {
                    biometricService.authenticate()
                }
            }
        }
    }
}
