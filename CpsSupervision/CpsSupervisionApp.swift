import SwiftUI

@main
struct CpsSupervisionApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var biometricService = BiometricService()
    @StateObject private var sharingService = SharingService.shared
    @AppStorage(Constants.UserDefaultsKey.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            Group {
                if !hasCompletedOnboarding {
                    OnboardingView {
                        hasCompletedOnboarding = true
                        biometricService.lock()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            biometricService.authenticate()
                        }
                    }
                } else if biometricService.isLocked {
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
            .animation(.easeInOut(duration: 0.3), value: hasCompletedOnboarding)
            .animation(.easeInOut(duration: 0.3), value: biometricService.isLocked)
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard hasCompletedOnboarding else { return }
            if newPhase == .background {
                biometricService.lock()
            } else if newPhase == .active && biometricService.isLocked {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    biometricService.authenticate()
                }
            }
        }
    }
}
