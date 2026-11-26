//
//  ScanPlanFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 07/02/2026.
//

import AVFoundation
import ComposableArchitecture
import HealthHub
import PhotosUI
import SharedModels
import SwiftUI

extension ScanPlanFeature {

    @ObservableState
    struct State {

        // MARK: - Properties

        /// The color representing the training readiness level.
        @Shared(.inMemory(.readinessLevelColor))
        var color: Color = .gray

        /// Current view state of the scan plan flow.
        var viewState: ScanPlanViewState = .idle

        /// Whether the photo picker is currently presented.
        var isPickerPresented = false

        /// Whether the board camera is currently presented.
        var isCameraPresented = false

        /// Photo held while the camera slides away; the crop sheet opens only once it is gone.
        var pendingCameraPhoto: Data?

        /// Whether the phone has a back camera; the simulator has none, so the button hides there.
        var isCameraAvailable = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) != nil

        /// The selected photo picker item.
        var selectedItem: PhotosPickerItem?

        /// Raw image data loaded from the selected photo.
        var selectedImageData: Data?

        /// Text extracted from the image via OCR, editable by user.
        var extractedText: String = ""

        /// The board as the model read it; nil until parsing succeeds.
        var extractedWorkout: ScannedBoard?

        /// Which pipeline stage produced the current `.failed` state —
        /// drives smart retry (re-run only the failed stage, keep earlier work).
        var failedStage: FailedStage?

        /// Backend that turns the scan into a workout; persisted so it survives relaunch.
        @Shared(.appStorage("workoutParsingBackend"))
        var parsingBackend: WorkoutParsingBackend = .claudeVision

        /// Model the scan runs on; only a debug build can move it off the default.
        @Shared(.appStorage("scanModelChoice"))
        var scanModel: ScanModelChoice = .serverDefault

        /// Whether the user agreed to send plans to the AI service; asked once, revocable in settings.
        @Shared(.appStorage(.aiProcessingConsent))
        var isAIProcessingAllowed = false

        // MARK: - Destination

        /// Consent asked before the first plan leaves the phone.
        @Presents var alert: AlertState<Action.Alert>?

        /// Workout preview destination (navigation).
        @Presents var workoutPreview: WorkoutPreviewFeature.State?

        /// Crop sheet for a photo picked from the library.
        @Presents var photoCrop: PhotoCropFeature.State?
    }

    /// Pipeline stage that failed — determines what a Retry re-runs.
    enum FailedStage: Equatable {
        case photoLoad
        case ocr
        case parsing
    }

}
