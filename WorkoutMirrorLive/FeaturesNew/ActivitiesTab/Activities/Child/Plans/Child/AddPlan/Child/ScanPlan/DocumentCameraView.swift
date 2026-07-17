//
//  DocumentCameraView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 16/07/2026.
//

import SwiftUI
import UIKit
import VisionKit

/// System document scanner presented for photographing a workout plan.
///
/// Deliberately `VNDocumentCameraViewController` instead of a plain camera
/// picker: the scanner auto-detects page edges, crops and corrects perspective,
/// which is exactly the input `RecognizeDocumentsRequest` OCR performs best on.
struct DocumentCameraView: UIViewControllerRepresentable {

    /// Outcome of a scanner session — a user cancel is not an error and the
    /// reducer reacts differently to each.
    enum ScanResult {
        case scanned(Data)
        case cancelled
        case failed
    }

    /// Called once when the scanner session ends.
    let onResult: (ScanResult) -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onResult: onResult)
    }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {

        private let onResult: (ScanResult) -> Void

        init(onResult: @escaping (ScanResult) -> Void) {
            self.onResult = onResult
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            // Single-page flow: a workout plan is one notebook page. Extra
            // pages the user scanned are ignored (documented in IOS-00106 plan).
            guard scan.pageCount > 0 else {
                onResult(.failed)
                return
            }
            let page = scan.imageOfPage(at: 0)
            Task {
                // JPEG-encoding a full-resolution page takes hundreds of ms —
                // hop off the main actor so the dismiss animation stays smooth.
                if let data = await Self.encodedJPEG(from: page) {
                    onResult(.scanned(data))
                } else {
                    onResult(.failed)
                }
            }
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onResult(.cancelled)
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: any Error
        ) {
            onResult(.failed)
        }

        /// `nonisolated async` runs on the global executor, not the main actor.
        private nonisolated static func encodedJPEG(from image: UIImage) async -> Data? {
            image.jpegData(compressionQuality: 0.8)
        }
    }
}
