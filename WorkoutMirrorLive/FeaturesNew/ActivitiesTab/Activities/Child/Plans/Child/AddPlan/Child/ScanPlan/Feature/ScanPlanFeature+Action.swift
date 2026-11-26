//
//  ScanPlanFeature+Action.swift
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

    @CasePathable
    enum Action: ViewAction, BindableAction {

        case binding(BindingAction<State>)
        case view(View)
        case `internal`(Internal)
        case workoutPreview(PresentationAction<WorkoutPreviewFeature.Action>)
        case photoCrop(PresentationAction<PhotoCropFeature.Action>)
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)

        enum Alert {

            /// Called when the user agrees to send plans to the AI service.
            case aiProcessingAllowed
        }

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

            /// The camera closed — the full photo, or `nil` when the user cancelled.
            case cameraPhotoTaken(Data?)

            /// The camera could not run (no camera, no permission) — distinct from a user cancel.
            case cameraFailed

            /// The camera finished sliding away, so another sheet may now open.
            case cameraDismissed

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

            /// Called when user gives up on scanning and wants to type the plan in.
            case addManuallyTapped

            /// Called when user picks a parsing backend (DEBUG picker).
            case parsingBackendChanged(WorkoutParsingBackend)

            /// Called when user picks the model to scan with (DEBUG picker).
            case scanModelChanged(ScanModelChoice)
        }

        enum Internal {

            /// Image data loaded from the selected photo picker item; nil when loading failed.
            case galleryPhotoLoaded(Data?)

            /// Image data ready to scan (document scan, or a cropped gallery photo).
            case imageLoaded(Data?)

            /// OCR text extracted successfully from image.
            case textExtracted(String)

            /// Workout parsing completed successfully.
            case parsingCompleted(ScannedBoard)

            /// A pipeline stage failed with presentable copy.
            case extractionFailed(ScanFailure, FailedStage)
        }
    }

}
