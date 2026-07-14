//
//  ScanPlanFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 07/02/2026.
//

import ComposableArchitecture
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

        /// The selected photo picker item.
        var selectedItem: PhotosPickerItem?

        /// Raw image data loaded from the selected photo.
        var selectedImageData: Data?

        /// Text extracted from the image via OCR, editable by user.
        var extractedText: String = ""

        /// Structured workout extracted from OCR text via Foundation Models.
        var extractedWorkout: ExtractedWorkout?

        // MARK: - Destination

        /// Workout preview destination (navigation).
        @Presents var workoutPreview: WorkoutPreviewFeature.State?

        /// API key entry sheet.
        @Presents var apiKeyEntry: APIKeyEntryFeature.State?
    }

}
