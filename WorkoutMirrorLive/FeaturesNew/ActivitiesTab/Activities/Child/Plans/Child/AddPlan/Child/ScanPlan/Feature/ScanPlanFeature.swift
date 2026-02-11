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
                        let result = try await extractionClient.extractWorkout(imageData)
                        await send(.internal(.extractionCompleted(result)))
                    } catch {
                        await send(.internal(.extractionFailed(error.localizedDescription)))
                    }
                }

            case .view(.retryTapped):
                state.selectedImageData = nil
                state.extractedText = ""
                state.extractedWorkout = nil
                state.viewState = .idle
                return .none

            case .view(.clearImageTapped):
                state.selectedImageData = nil
                state.extractedText = ""
                state.extractedWorkout = nil
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

            case let .internal(.extractionCompleted(workout)):
                state.extractedText = workout.rawText
                state.extractedWorkout = workout
                state.viewState = .textReady
                print("[ScanPlanFeature] Extraction completed: \(workout.name)")
                print("[ScanPlanFeature] Sections: \(workout.sections.map { $0.type.rawValue })")
                print("[ScanPlanFeature] Estimated time: \(workout.totalEstimatedMinutes) min")
                return .none

            case let .internal(.extractionFailed(error)):
                state.viewState = .failed(error)
                return .none
            }
        }
    }

}
