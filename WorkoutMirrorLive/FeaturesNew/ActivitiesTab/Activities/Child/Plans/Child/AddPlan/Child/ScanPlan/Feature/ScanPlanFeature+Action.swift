//
//  ScanPlanFeature+Action.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 07/02/2026.
//

import ComposableArchitecture
import PhotosUI
import SharedModels
import SwiftUI

extension ScanPlanFeature {

    @CasePathable
    enum Action: ViewAction, BindableAction {

        case binding(BindingAction<State>)
        case view(View)
        case `internal`(Internal)
        case workoutPreview(PresentationAction<WorkoutPreviewFeature.Action>)
        case apiKeyEntry(PresentationAction<APIKeyEntryFeature.Action>)
        case delegate(Delegate)

        enum Delegate {
            /// WorkoutPreview saved — passes session up so AddPlanFeature can persist.
            case saved(TrainingSession)
        }

        @CasePathable
        enum View {

            /// Called when user taps "Select Photo" button.
            case selectPhotoTapped

            /// Called when user taps "Take Photo" button.
            case takePhotoTapped

            /// Called when the document camera finishes — JPEG data of the
            /// scanned page, or `nil` when the user cancelled.
            case documentScanned(Data?)

            /// Called when the document camera failed (scanner error or
            /// JPEG encoding failure) — distinct from a user cancel.
            case documentScanFailed

            /// Called when user taps "Edit Text" on a parsing failure.
            case editTextTapped

            /// Called when user selects or deselects a photo in the picker.
            case selectedPhotoChanged(PhotosPickerItem?)

            /// Called when user taps "Continue" to parse OCR text and preview workout.
            case continueButtonTapped

            /// Called when user taps "Retry" after a failure.
            case retryTapped

            /// Called when user taps "Clear" to remove selected image.
            case clearImageTapped

            /// Called when user taps the key icon in toolbar (add/manage API key).
            case apiKeySettingsTapped
        }

        enum Internal {

            /// Image data loaded from the selected photo picker item.
            case imageLoaded(Data?)

            /// OCR text extracted successfully from image.
            case textExtracted(String)

            /// Workout parsing completed successfully.
            case parsingCompleted(ExtractedWorkout)

            /// A pipeline stage failed with an error message.
            case extractionFailed(String, FailedStage)
        }
    }

}
