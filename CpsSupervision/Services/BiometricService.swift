import Foundation
import LocalAuthentication

@MainActor
class BiometricService: ObservableObject {
    @Published var isLocked = false
    @Published var authError: String?

    var biometricType: LABiometryType {
        let ctx = LAContext()
        _ = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return ctx.biometryType
    }

    var biometricName: String {
        switch biometricType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default: return "Passcode"
        }
    }

    var biometricSystemImageName: String {
        switch biometricType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        default: return "lock.fill"
        }
    }

    init() {
        // Lock on startup if onboarding was already completed
        isLocked = UserDefaults.standard.bool(forKey: Constants.UserDefaultsKey.hasCompletedOnboarding)
    }

    func lock() {
        isLocked = true
    }

    func authenticate() {
        let ctx = LAContext()
        var error: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            // Device has no passcode set — allow access
            isLocked = false
            return
        }
        ctx.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: "Access your supervision logs"
        ) { success, authError in
            DispatchQueue.main.async {
                if success {
                    self.isLocked = false
                    self.authError = nil
                } else {
                    self.authError = authError?.localizedDescription
                }
            }
        }
    }
}
