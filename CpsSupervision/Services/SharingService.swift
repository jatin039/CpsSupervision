import Foundation
import CoreData
import CloudKit
import UIKit
import SwiftUI

@MainActor
class SharingService: ObservableObject {
    static let shared = SharingService()

    @Published var activeShare: CKShare?
    @Published var activeContainer: CKContainer?
    @Published var sharingError: String?

    private let stack = PersistenceController.shared

    // Creates or retrieves a CKShare for a Child, then presents UICloudSharingController
    func share(child: Child) async {
        do {
            let (_, share, ckContainer) = try await stack.container.share([child], to: nil)
            share[CKShare.SystemFieldKey.title] = "CPS Case: \(child.wrappedName)" as CKRecordValue
            share[CKShare.SystemFieldKey.shareType] = "Supervision Logs" as CKRecordValue
            share.publicPermission = .none
            activeShare = share
            activeContainer = ckContainer
        } catch {
            sharingError = error.localizedDescription
        }
    }

    func isShared(_ child: Child) -> Bool {
        stack.container.isRecord(forManagedObjectID: child.objectID) != nil
    }
}

// SwiftUI wrapper for UICloudSharingController
struct CloudSharingSheet: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer
    var onDismiss: () -> Void = {}

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = UICloudSharingController(share: share, container: container)
        controller.delegate = context.coordinator
        controller.availablePermissions = [.allowReadWrite, .allowPrivate]
        return controller
    }

    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onDismiss: onDismiss) }

    class Coordinator: NSObject, UICloudSharingControllerDelegate {
        let onDismiss: () -> Void
        init(onDismiss: @escaping () -> Void) { self.onDismiss = onDismiss }

        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {}
        func itemTitle(for csc: UICloudSharingController) -> String? { "CPS Supervision Log" }
        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) { onDismiss() }
        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) { onDismiss() }
    }
}
