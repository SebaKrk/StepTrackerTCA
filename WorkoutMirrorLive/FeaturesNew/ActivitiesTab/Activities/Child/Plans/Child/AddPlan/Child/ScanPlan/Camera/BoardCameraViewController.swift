//
//  BoardCameraViewController.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 26/11/2026.
//

import AVFoundation
import AVKit
import OSLog
import UIKit

/// One-tap camera for a training board: preview, shutter, photo out — cropping happens next.
///
/// UIKit owns the capture session the same way `ScannerViewController` does, so the
/// session never lives in SwiftUI state.
final class BoardCameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {

    /// Called once with the photo, a cancel or a failure; set by `BoardCameraView`.
    var onResult: ((BoardCameraResult) -> Void)?

    /// Capture pipeline: back camera in, still photos out.
    private let session = AVCaptureSession()

    /// Still photo output; its size is fixed before the session starts.
    private let photoOutput = AVCapturePhotoOutput()

    /// Session work runs here: configuring and starting a session blocks for a few hundred ms.
    private let sessionQueue = DispatchQueue(label: "board.camera.session")

    /// Live preview filling the screen.
    private lazy var previewLayer = AVCaptureVideoPreviewLayer(session: session)

    /// Keeps the photo upright however the phone is held.
    private var rotationCoordinator: AVCaptureDevice.RotationCoordinator?

    /// The camera in use, for tap-to-focus.
    private var device: AVCaptureDevice?

    /// Photo size near 12 MP — the model reads 1568 px, more only costs memory.
    private var photoDimensions: CMVideoDimensions?

    /// True once the session runs; taps before that are ignored.
    private var isReady = false

    /// True from the shutter until the photo arrives, so a double tap takes one photo.
    private var isCapturing = false

    /// True once `onResult` fired; the controller reports exactly once.
    private var hasFinished = false

    /// True after the first appearance, so returning from the background does not set up twice.
    private var hasStarted = false

    /// Big round shutter at the bottom.
    private let shutterButton = UIButton(type: .custom)

    /// Close button at the top.
    private let closeButton = UIButton(type: .system)

    /// Short tip on how to frame the board.
    private let hintLabel = UILabel()

    /// Camera log channel.
    private nonisolated static let logger = Logger(subsystem: "MyFitnessJournal", category: "BoardCamera")

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(previewLayer, at: 0)
        setupControls()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !hasStarted else { return }
        hasStarted = true
        // Asked after the cover is on screen, so a refusal can dismiss it cleanly.
        Task { [weak self] in
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            guard let self else { return }
            guard granted else {
                Self.logger.error("Camera permission denied or restricted")
                self.finish(.failed)
                return
            }
            self.startSession()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sessionQueue.async { [session] in
            session.stopRunning()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.layer.bounds
    }

    // MARK: - Session

    /// Configures and starts the session off the main thread, then hands the camera back to the UI.
    private func startSession() {
        sessionQueue.async { [weak self, session, photoOutput] in
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: device)
            else {
                DispatchQueue.main.async { self?.finish(.failed) }
                return
            }

            session.beginConfiguration()
            session.sessionPreset = .photo
            guard session.canAddInput(input), session.canAddOutput(photoOutput) else {
                session.commitConfiguration()
                DispatchQueue.main.async { self?.finish(.failed) }
                return
            }
            session.addInput(input)
            session.addOutput(photoOutput)
            photoOutput.maxPhotoQualityPrioritization = .balanced
            session.commitConfiguration()

            // Read after the commit: the preset has picked the format whose sizes are valid.
            let dimensions = Self.photoDimensions(for: device.activeFormat)
            if let dimensions {
                photoOutput.maxPhotoDimensions = dimensions
            }
            Self.configureFocus(device)
            session.startRunning()

            DispatchQueue.main.async {
                self?.cameraDidStart(device: device, dimensions: dimensions)
            }
        }
    }

    private func cameraDidStart(device: AVCaptureDevice, dimensions: CMVideoDimensions?) {
        self.device = device
        photoDimensions = dimensions
        let coordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: previewLayer)
        rotationCoordinator = coordinator
        let previewAngle = coordinator.videoRotationAngleForHorizonLevelPreview
        if let connection = previewLayer.connection, connection.isVideoRotationAngleSupported(previewAngle) {
            connection.videoRotationAngle = previewAngle
        }
        isReady = true
    }

    /// Continuous focus and exposure follow the board as the phone moves.
    private nonisolated static func configureFocus(_ device: AVCaptureDevice) {
        do {
            try device.lockForConfiguration()
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            device.unlockForConfiguration()
        } catch {
            logger.error("Focus setup failed: \(error.localizedDescription)")
        }
    }

    /// The largest supported size up to about 12 MP, or the smallest one when all are larger.
    private nonisolated static func photoDimensions(for format: AVCaptureDevice.Format) -> CMVideoDimensions? {
        let sizes = format.supportedMaxPhotoDimensions
        let pixels = { (size: CMVideoDimensions) in Int(size.width) * Int(size.height) }
        let fitting = sizes.filter { pixels($0) <= 12_600_000 }
        return fitting.max { pixels($0) < pixels($1) } ?? sizes.min { pixels($0) < pixels($1) }
    }

    // MARK: - Capture

    private func capturePhoto() {
        guard isReady, !isCapturing, !hasFinished else { return }
        isCapturing = true
        shutterButton.isEnabled = false

        let settings = AVCapturePhotoSettings()
        settings.flashMode = .off
        settings.photoQualityPrioritization = .balanced
        if let photoDimensions {
            settings.maxPhotoDimensions = photoDimensions
        }
        if let angle = rotationCoordinator?.videoRotationAngleForHorizonLevelCapture,
           let connection = photoOutput.connection(with: .video),
           connection.isVideoRotationAngleSupported(angle) {
            connection.videoRotationAngle = angle
        }
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: (any Error)?
    ) {
        let data = error == nil ? photo.fileDataRepresentation() : nil
        let failure = error?.localizedDescription ?? "no data"
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.isCapturing = false
            if let data {
                self.finish(.captured(data))
            } else {
                Self.logger.error("Photo capture failed: \(failure)")
                self.shutterButton.isEnabled = true
            }
        }
    }

    private func finish(_ result: BoardCameraResult) {
        guard !hasFinished else { return }
        hasFinished = true
        onResult?(result)
    }

    // MARK: - Focus

    @objc private func previewTapped(_ gesture: UITapGestureRecognizer) {
        guard let device else { return }
        let point = previewLayer.captureDevicePointConverted(fromLayerPoint: gesture.location(in: view))
        do {
            try device.lockForConfiguration()
            // Continuous modes keep the tapped point and go on following the board from there.
            if device.isFocusPointOfInterestSupported, device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusPointOfInterest = point
                device.focusMode = .continuousAutoFocus
            }
            if device.isExposurePointOfInterestSupported, device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposurePointOfInterest = point
                device.exposureMode = .continuousAutoExposure
            }
            device.unlockForConfiguration()
        } catch {
            Self.logger.error("Tap to focus failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Controls

    private func setupControls() {
        configureShutterButton()
        configureCloseButton()
        configureHintLabel()

        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(previewTapped)))
        // Volume buttons and Camera Control take the photo too.
        view.addInteraction(AVCaptureEventInteraction { [weak self] event in
            if event.phase == .ended { self?.capturePhoto() }
        })

        [shutterButton, closeButton, hintLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        NSLayoutConstraint.activate([
            shutterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shutterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            shutterButton.widthAnchor.constraint(equalToConstant: 76),
            shutterButton.heightAnchor.constraint(equalToConstant: 76),

            closeButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),

            hintLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hintLabel.bottomAnchor.constraint(equalTo: shutterButton.topAnchor, constant: -20),
            hintLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
        ])
    }

    private func configureShutterButton() {
        shutterButton.backgroundColor = .white
        shutterButton.layer.cornerRadius = 38
        shutterButton.layer.borderWidth = 4
        shutterButton.layer.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor
        shutterButton.accessibilityLabel = String(localized: "Take Photo")
        shutterButton.addAction(UIAction { [weak self] _ in self?.capturePhoto() }, for: .touchUpInside)
    }

    private func configureCloseButton() {
        let symbol = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        closeButton.setImage(UIImage(systemName: "xmark", withConfiguration: symbol), for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        closeButton.layer.cornerRadius = 22
        closeButton.accessibilityLabel = String(localized: "Cancel")
        closeButton.addAction(UIAction { [weak self] _ in self?.finish(.cancelled) }, for: .touchUpInside)
    }

    private func configureHintLabel() {
        hintLabel.text = String(localized: "Fill the frame with the board, no flash")
        hintLabel.font = .preferredFont(forTextStyle: .footnote)
        hintLabel.textColor = .white
        hintLabel.textAlignment = .center
        hintLabel.numberOfLines = 0
        hintLabel.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        hintLabel.layer.cornerRadius = 8
        hintLabel.clipsToBounds = true
    }
}
