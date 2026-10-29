//
//  ScanPlanFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 07/02/2026.
//

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

        /// Whether the document camera scanner is currently presented.
        var isCameraPresented = false

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

        // MARK: - Destination

        /// Workout preview destination (navigation).
        @Presents var workoutPreview: WorkoutPreviewFeature.State?

        /// API key entry sheet.
        @Presents var apiKeyEntry: APIKeyEntryFeature.State?

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
