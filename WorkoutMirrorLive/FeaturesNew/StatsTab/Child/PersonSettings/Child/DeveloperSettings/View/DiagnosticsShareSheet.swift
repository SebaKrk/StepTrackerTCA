//
//  DiagnosticsShareSheet.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 14/11/2026.
//

import SwiftUI

/// System share sheet for the diagnostics archive.
///
/// SwiftUI has no programmatically-presentable `ShareLink`, and the archive only
/// exists once it has been built, so presentation goes through UIKit.
struct DiagnosticsShareSheet: UIViewControllerRepresentable {

    /// The archive handed to the share sheet.
    let url: URL

    /// Called once the sheet closes, whether or not anything was sent.
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in onDismiss() }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
