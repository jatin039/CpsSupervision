import SwiftUI

struct LockView: View {
    @EnvironmentObject var biometricService: BiometricService

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 72))
                .foregroundStyle(.blue)
                .symbolEffect(.pulse)

            VStack(spacing: 8) {
                Text("CPS Supervision")
                    .font(.largeTitle.bold())
                Text("Your supervision records are protected")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let error = biometricService.authError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button {
                biometricService.authenticate()
            } label: {
                Label("Unlock with \(biometricService.biometricName)",
                      systemImage: biometricService.biometricSystemImageName)
                    .font(.headline)
                    .frame(maxWidth: 280)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Spacer()
        }
        .padding()
        .onAppear { biometricService.authenticate() }
    }
}

#Preview {
    LockView()
        .environmentObject(BiometricService())
}
