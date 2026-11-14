//
//  DiagnosticsMailComposer.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 14/11/2026.
//

import MessageUI
import SwiftUI

/// Pre-addressed mail with the diagnostics archive attached.
///
/// Only presented when the device can send mail; otherwise the share sheet
/// takes over, because an unconfigured Mail app refuses silently.
struct DiagnosticsMailComposer: UIViewControllerRepresentable {

    /// The archive attached to the message.
    let url: URL

    /// Called once the composer closes, whether sent, saved or cancelled.
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        controller.setToRecipients([DiagnosticsRecipient.address])
        controller.setSubject(subject)
        controller.setMessageBody(
            String(localized: "Describe what went wrong, and roughly when it happened:\n\n"),
            isHTML: false
        )

        if let data = try? Data(contentsOf: url) {
            controller.addAttachmentData(
                data,
                mimeType: "application/zip",
                fileName: url.lastPathComponent
            )
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }

    // MARK: - Private Properties

    /// Names the install in the subject, so parallel builds are told apart in the inbox.
    private var subject: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        let bundle = Bundle.main.bundleIdentifier ?? "?"

        return "MyFitnessJournal \(version) (\(build)) — \(bundle)"
    }

    // MARK: - Coordinator

    @MainActor
    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {

        /// Called once the composer closes.
        private let onDismiss: () -> Void

        init(onDismiss: @escaping () -> Void) {
            self.onDismiss = onDismiss
        }

        nonisolated func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            MainActor.assumeIsolated {
                onDismiss()
            }
        }
    }
}
