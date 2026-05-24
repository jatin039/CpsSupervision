import SwiftUI
import LocalAuthentication

struct OnboardingView: View {
    var onComplete: () -> Void

    @AppStorage(Constants.UserDefaultsKey.currentUserName) private var savedUserName = ""
    @State private var step = 0
    @State private var userName = ""
    @State private var biometricDone = false
    @State private var biometricFailed = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            switch step {
            case 0: welcomeStep
            case 1: nameStep
            case 2: faceIDStep
            default: EmptyView()
            }
        }
        .animation(.easeInOut(duration: 0.35), value: step)
    }

    // MARK: Step 0 — Welcome

    private var welcomeStep: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 24) {
                Image("AppIcon")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .shadow(color: .black.opacity(0.12), radius: 12, y: 4)

                VStack(spacing: 10) {
                    Text("CPS Supervision")
                        .font(.largeTitle.bold())
                    Text("Secure supervision logs for\nchild welfare professionals.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            Spacer()
            OnboardingButton("Get Started") { step = 1 }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
        }
    }

    // MARK: Step 1 — Name

    private var nameStep: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 32) {
                VStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.blue)
                    Text("What's your name?")
                        .font(.title.bold())
                    Text("Your name appears on supervision logs you create.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                TextField("Full name", text: $userName)
                    .font(.title3)
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground),
                                in: RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 32)
            }
            Spacer()
            OnboardingButton("Continue", disabled: userName.trimmingCharacters(in: .whitespaces).isEmpty) {
                savedUserName = userName.trimmingCharacters(in: .whitespaces)
                step = 2
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }

    // MARK: Step 2 — Face ID

    private var faceIDStep: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.12))
                        .frame(width: 120, height: 120)
                    Image(systemName: biometricSystemImageName)
                        .font(.system(size: 52))
                        .foregroundStyle(.blue)
                }

                VStack(spacing: 10) {
                    Text("Secure Your Records")
                        .font(.title.bold())
                    Text("Supervision logs contain sensitive information. \(biometricName) is required every time you open the app.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                if biometricFailed {
                    Text("Biometrics unavailable — your device passcode will be used instead.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            Spacer()

            VStack(spacing: 12) {
                if !biometricDone && !biometricFailed {
                    OnboardingButton("Enable \(biometricName)") {
                        requestBiometricPermission()
                    }
                    .padding(.horizontal, 32)
                } else {
                    OnboardingButton("Get Started") {
                        onComplete()
                    }
                    .padding(.horizontal, 32)
                }
            }
            .padding(.bottom, 48)
        }
    }

    // MARK: Helpers

    private var biometricName: String {
        let ctx = LAContext()
        _ = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch ctx.biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        default: return "Biometrics"
        }
    }

    private var biometricSystemImageName: String {
        let ctx = LAContext()
        _ = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch ctx.biometryType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        default: return "lock.shield.fill"
        }
    }

    private func requestBiometricPermission() {
        let ctx = LAContext()
        var error: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            biometricFailed = true
            return
        }
        ctx.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Set up \(biometricName) to protect your supervision records"
        ) { success, _ in
            DispatchQueue.main.async {
                if success { biometricDone = true } else { biometricFailed = true }
            }
        }
    }
}

private struct OnboardingButton: View {
    let title: String
    var disabled: Bool = false
    let action: () -> Void

    init(_ title: String, disabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.disabled = disabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(disabled ? Color.gray.opacity(0.3) : Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(disabled)
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
