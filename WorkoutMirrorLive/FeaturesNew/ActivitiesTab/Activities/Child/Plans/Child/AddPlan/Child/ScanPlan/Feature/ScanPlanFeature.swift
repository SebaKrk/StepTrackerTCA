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

    // MARK: - Dependency

    @Dependency(\.apiKeyClient) var apiKeyClient
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

            case .view(.apiKeySettingsTapped):
                let hasKey = apiKeyClient.load() != nil
                state.apiKeyEntry = APIKeyEntryFeature.State(hasExistingKey: hasKey)
                return .none

            case .view(.continueButtonTapped):
                guard !state.extractedText.isEmpty else { return .none }
                guard apiKeyClient.load() != nil else {
                    state.apiKeyEntry = APIKeyEntryFeature.State(hasExistingKey: false)
                    return .none
                }
                state.viewState = .processingOCR
                return .run { [text = state.extractedText] send in
                    do {
                        let workout = try await extractionClient.parseWorkout(text)
                        await send(.internal(.parsingCompleted(workout)))
                    } catch {
                        print("❌ [ScanPlan] Parsing error: \(error)")
                        dump(error)
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
                state.viewState = .processingOCR
                // Auto-start OCR after image loaded
                return .run { send in
                    do {
                        let rawText = try await extractionClient.extractText(data)
                        await send(.internal(.textExtracted(rawText)))
                    } catch {
                        print("❌ [ScanPlan] OCR error: \(error)")
                        dump(error)
                        await send(.internal(.extractionFailed(error.localizedDescription)))
                    }
                }

            case let .internal(.textExtracted(rawText)):
                state.extractedText = rawText
                state.viewState = .textReady
                return .none

            case let .internal(.parsingCompleted(workout)):
                state.extractedWorkout = workout

                // Debug: Print final TrainingSession as JSON
                let trainingSession = workout.toTrainingSession()
                dump(trainingSession)

                // MARK: - Check if extraction returned empty result (FM unavailable fallback)

                guard !workout.sections.isEmpty else {
                    state.viewState = .unavailable("""
                        Foundation Models unavailable on this device.

                        OCR extracted text successfully, but structured parsing requires:
                        • iPhone 15 Pro / Pro Max or newer
                        • iPad with M1+ chip
                        • Mac with Apple Silicon
                        • iOS 26+ with Apple Intelligence enabled

                        Cloud API fallback coming soon.
                        """)
                    return .none
                }

                // Auto-navigate to preview after successful parsing
                state.workoutPreview = WorkoutPreviewFeature.State(trainingSession: trainingSession)

                return .none

            case let .internal(.extractionFailed(error)):
                state.viewState = .failed(error)
                return .none

                // MARK: - Destination Action

            case .destination(.presented(.apiKeyEntry(.delegate(.keySaved)))):
                // Key saved → dismiss sheet and retry continue action
                state.apiKeyEntry = nil
                return .run { send in
                    await send(.view(.continueButtonTapped))
                }

            case .destination(.presented(.apiKeyEntry(.delegate(.keyDeleted)))):
                // Key deleted → dismiss sheet
                state.apiKeyEntry = nil
                return .none

            case .destination(.presented(.workoutPreview(.view(.editButtonTapped)))):
                // Handled internally by WorkoutPreviewFeature (opens editor).
                return .none

            case .destination(.dismiss):
                // User dismissed preview (back button) - reset to idle
                state.viewState = .idle
                state.selectedImageData = nil
                state.extractedText = ""
                state.extractedWorkout = nil
                return .none

            case .destination:
                return .none
            }
        }
        .ifLet(\.$workoutPreview, action: \.destination.workoutPreview) {
            WorkoutPreviewFeature()
        }
        .ifLet(\.$apiKeyEntry, action: \.destination.apiKeyEntry) {
            APIKeyEntryFeature()
        }
    }

}
