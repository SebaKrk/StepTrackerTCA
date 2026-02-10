//
//  ScanPlanFeature+Action.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 07/02/2026.
//

import ComposableArchitecture
import PhotosUI
import SwiftUI

extension ScanPlanFeature {

    @CasePathable
    enum Action: ViewAction, BindableAction {

        case binding(BindingAction<State>)
        case view(View)
        case `internal`(Internal)

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
        }

        enum Internal {

            /// Image data loaded from the selected photo picker item.
            case imageLoaded(Data?)

            /// OCR completed successfully with extracted text.
            case ocrCompleted(String)

            /// OCR failed with an error message.
            case ocrFailed(String)
        }
    }

}
