//
//  ScanPlanFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 07/02/2026.
//

import ComposableArchitecture
import PhotosUI
import SwiftUI
import SharedModels

/// Feature responsible for extracting a workout plan from a photo.
///
/// Flow: Select photo → Load image data → Extract text → Edit extracted text.
/// The extraction strategy (on-device OCR+FM vs cloud Claude API) is determined
/// at runtime by ``WorkoutExtractionClient`` based on device capabilities.
@Reducer
struct ScanPlanFeature {

    @Dependency(\.workoutExtractionClient) var extractionClient

    // MARK: - Body

    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce { state, action in
            switch action {

            case .binding:
                return .none

                // MARK: - View Action

            case .view(.selectPhotoTapped):
                state.isPickerPresented = true
                return .none

            case let .view(.selectedPhotoChanged(item)):
                guard let item else { return .none }
                return .run { send in
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        await send(.internal(.imageLoaded(data)))
                    } else {
                        await send(.internal(.imageLoaded(nil)))
                    }
                }

            case .view(.extractTextTapped):
                guard let imageData = state.selectedImageData else { return .none }
                state.viewState = .processingOCR
                return .run { send in
                    do {
                        let text = try await extractionClient.extractWorkout(imageData)
                        await send(.internal(.ocrCompleted(text)))
                    } catch {
                        await send(.internal(.ocrFailed(error.localizedDescription)))
                    }
                }

            case .view(.retryTapped):
                state.selectedImageData = nil
                state.extractedText = ""
                state.viewState = .idle
                return .none

            case .view(.clearImageTapped):
                state.selectedImageData = nil
                state.extractedText = ""
                state.viewState = .idle
                return .none

                // MARK: - Internal Action

            case let .internal(.imageLoaded(data)):
                guard let data else {
                    state.viewState = .failed(String(localized: "Could not load the selected image."))
                    return .none
                }
                state.selectedImageData = data
                state.viewState = .imageSelected
                return .none

            case let .internal(.ocrCompleted(text)):
                state.extractedText = text
                state.viewState = .textReady
                return .none

            case let .internal(.ocrFailed(error)):
                state.viewState = .failed(error)
                return .none
            }
        }
    }

}
