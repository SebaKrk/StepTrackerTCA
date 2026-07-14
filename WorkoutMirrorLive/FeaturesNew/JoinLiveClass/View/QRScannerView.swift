//
//  QRScannerView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 11/06/2026.
//

import AVFoundation
import OSLog
import SharedModels
import SwiftUI
import UIKit

/// SwiftUI wrapper na `AVCaptureSession`-based scanner z `.qr` metadata detection.
///
/// **Lifecycle**:
/// - `viewDidLoad` → camera permission request (lazy — tylko jeśli notDetermined)
/// - `viewDidAppear` → `session.startRunning()` na background queue (~200ms blocking init)
/// - `viewWillDisappear` → `session.stopRunning()` (bateria + red indicator dot)
/// - Pierwszy scan → `session.stopRunning()` + `onScanned(payload)` callback (one-shot)
///
/// **Wymaga `NSCameraUsageDescription`** w Info.plist — bez tego app crashuje przy
/// `AVCaptureDevice.requestAccess(for: .video)` (Apple privacy enforcement).
///
/// **Test note**: w simulator camera nie działa (Apple limitation) — `AVCaptureDevice.default`
/// zwraca nil, session pozostaje pusta, callback nigdy nie odpala. Test na real device.
struct QRScannerView: UIViewControllerRepresentable {

    /// Wywoływane raz przy pierwszym successful scan'ie. Payload to `stringValue`
    /// z `AVMetadataMachineReadableCodeObject` — w naszym przypadku JSON `QRSessionPayload`.
    let onScanned: (String) -> Void

    func makeUIViewController(context: Context) -> ScannerViewController {
        let vc = ScannerViewController()
        vc.onScanned = onScanned
        return vc
    }

    func updateUIViewController(_ vc: ScannerViewController, context: Context) {
        // Callback może się zmienić (np. closure capture'uje aktualny store) —
        // refresh za każdym update'em.
        vc.onScanned = onScanned
    }
}

/// `UIViewController` orchestrating `AVCaptureSession` lifecycle + QR metadata detection.
final class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    /// Closure odpalana przy pierwszym successful scan'ie. Set z `QRScannerView.makeUIViewController`.
    var onScanned: ((String) -> Void)?

    /// AVFoundation capture pipeline — input (camera) + output (metadata detection).
    private let session = AVCaptureSession()

    /// Layer pokazujący live preview na `view.layer`. Resize'owany w `viewDidLayoutSubviews`.
    private var previewLayer: AVCaptureVideoPreviewLayer?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        requestCameraAndSetup()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // startRunning() blokuje main thread ~200ms (kamera init) — wywołujemy
        // na background queue żeby UI nie zacinało się przy push'u widoku.
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let session = self?.session, !session.isRunning else { return }
            session.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Stop session żeby zwolnić kamerę + ukryć red indicator dot na pasku (iOS 14+).
        // Plus oszczędność baterii — pipeline w tle dren'uje energię.
        session.stopRunning()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }

    // MARK: - Camera permission

    /// Pre-checks authorization status + lazy `requestAccess` tylko gdy notDetermined.
    /// Denied/restricted → tylko log error (user musi sam iść do Settings — Apple nigdy
    /// nie pokaże ponownego prompt'u). UI fallback dla denied state TODO w C3 lub polish.
    private func requestCameraAndSetup() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession()

        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard granted else {
                    Logger.gymRoom.error("[QRScanner] Camera permission denied during requestAccess")
                    return
                }
                DispatchQueue.main.async { self?.setupSession() }
            }

        case .denied, .restricted:
            Logger.gymRoom.error("[QRScanner] Camera permission denied/restricted — scanner inactive")

        @unknown default:
            Logger.gymRoom.error("[QRScanner] Unknown camera authorization status")
        }
    }

    // MARK: - AVCaptureSession setup

    private func setupSession() {
        // `AVCaptureDevice.default(for: .video)` zwraca nil w simulator — defensive
        // guard żeby setup nie crashował podczas live preview / unit tests.
        guard let device = AVCaptureDevice.default(for: .video) else {
            Logger.gymRoom.warning("[QRScanner] No video device available (simulator?)")
            return
        }

        guard let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            Logger.gymRoom.error("[QRScanner] Failed to create or add camera input")
            return
        }
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else {
            Logger.gymRoom.error("[QRScanner] Failed to add metadata output")
            return
        }
        session.addOutput(output)

        // Delegate na main queue — chcemy żeby callback `metadataOutput` wszedł
        // od razu w UI thread (do triggera SwiftUI state update'u).
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.frame = view.layer.bounds
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)
        self.previewLayer = preview

        Logger.gymRoom.info("[QRScanner] Session configured — ready to scan")
    }

    // MARK: - AVCaptureMetadataOutputObjectsDelegate

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let metadata = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let payload = metadata.stringValue else {
            return
        }

        // One-shot: stop session żeby nie spamować callback'iem dla każdego frame'a.
        // Konsument (JoinLiveClassFeature w C3) zdecyduje czy uruchomić scanner ponownie.
        session.stopRunning()
        Logger.gymRoom.info("[QRScanner] Scanned QR — payload length=\(payload.count) chars")
        onScanned?(payload)
    }
}

// MARK: - Previews

#Preview("Scanner (simulator = black screen)") {
    // W simulator camera nie działa — preview pokaże czarny ekran.
    // Test na real device. Callback log'owany do konsoli.
    QRScannerView { scanned in
        print("[Preview] Scanned: \(scanned)")
    }
}
