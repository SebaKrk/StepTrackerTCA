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
        case destination(PresentationAction<Destination.Action>)

        @CasePathable
        enum View {

            /// Called when user taps "Select Photo" button.
            case selectPhotoTapped

            /// Called when user selects or deselects a photo in the picker.
            case selectedPhotoChanged(PhotosPickerItem?)

            /// Called when user taps "Extract Text" to start OCR.
            case extractTextTapped

            /// Called when user taps "Retry" after a failure.
            case retryTapped

            /// Called when user taps "Clear" to remove selected image.
            case clearImageTapped

            /// Called when user taps "Preview Workout" button.
            case previewWorkoutTapped
        }

        enum Internal {

            /// Image data loaded from the selected photo picker item.
            case imageLoaded(Data?)

            /// Workout extraction completed successfully.
            case extractionCompleted(ExtractedWorkout)

            /// Workout extraction failed with an error message.
            case extractionFailed(String)
        }

        @Reducer
        enum Destination {
            case workoutPreview(WorkoutPreviewFeature)
        }
    }

}
