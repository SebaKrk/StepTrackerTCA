//
//  ScanPlanFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 07/02/2026.
//

import ComposableArchitecture
import HealthHub
import PhotosUI
import SwiftUI
import SharedModels

/// Feature responsible for extracting a workout plan from a photo.
///
/// Flow: Take/select photo → Load image data → Extract text (Vision OCR) →
/// Edit extracted text → Parse (Claude API) → Preview. Both steps go through
/// ``WorkoutExtractionClient``.
@Reducer
struct ScanPlanFeature {

    // MARK: - Cancel ID

    /// In-screen resets (Start Over / Retry) must kill in-flight work —
    /// otherwise a late OCR/parse result resurrects the state it belongs to.
    nonisolated enum CancelID: Hashable, Sendable {
        case photoLoad
        case ocr
        case parse
    }

    // MARK: - Dependency

    @Dependency(\.apiKeyClient) var apiKeyClient
    @Dependency(\.date) var date
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

            case .view(.takePhotoTapped):
                state.isCameraPresented = true
                return .none

            case let .view(.documentScanned(data)):
                state.isCameraPresented = false
                // User cancelled the scanner — stay where they were.
                guard let data else { return .none }
                return .send(.internal(.imageLoaded(data)))

            case .view(.documentScanFailed):
                state.isCameraPresented = false
                state.failedStage = .photoLoad
                state.viewState = .failed(String(localized: "Scanning failed. Try again."))
                return .none

            case .view(.editTextTapped):
                // Escape hatch from a parsing failure back to the editor —
                // the kept OCR text is the whole point of smart retry.
                state.failedStage = nil
                state.viewState = .textReady
                return .none

            case let .view(.selectedPhotoChanged(item)):
                guard let item else { return .none }
                // Synchronous, before the effect — loadTransferable can hit the
                // network (iCloud Photo Library) and the idle screen would linger.
                state.viewState = .loadingPhoto
                return .run { send in
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        await send(.internal(.imageLoaded(data)))
                    } else {
                        await send(.internal(.imageLoaded(nil)))
                    }
                }
                .cancellable(id: CancelID.photoLoad, cancelInFlight: true)

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
                state.failedStage = nil
                return .run { [text = state.extractedText] send in
                    do {
                        let workout = try await extractionClient.parseWorkout(text)
                        await send(.internal(.parsingCompleted(workout)))
                    } catch {
                        await send(.internal(.extractionFailed(ClaudeAPIError.userMessage(for: error), .parsing)))
                    }
                }
                .cancellable(id: CancelID.parse, cancelInFlight: true)

            case .view(.retryTapped):
                // Retry re-runs only the failed stage — the picked photo and
                // OCR text are already paid for; a transient network error
                // during parsing must not cost the user that work.
                switch state.failedStage {
                case .parsing where !state.extractedText.isEmpty:
                    state.failedStage = nil
                    return .send(.view(.continueButtonTapped))

                case .ocr:
                    guard let data = state.selectedImageData else {
                        return resetToIdle(&state)
                    }
                    state.failedStage = nil
                    return .send(.internal(.imageLoaded(data)))

                default:
                    return resetToIdle(&state)
                }

            case .view(.clearImageTapped):
                return resetToIdle(&state)

                // MARK: - Internal Action

            case let .internal(.imageLoaded(data)):
                guard let data else {
                    state.failedStage = .photoLoad
                    state.viewState = .failed(String(localized: "Could not load the selected image."))
                    return .none
                }
                state.selectedImageData = data
                state.viewState = .processingOCR
                state.failedStage = nil
                // Auto-start OCR after image loaded
                return .run { send in
                    do {
                        let rawText = try await extractionClient.extractText(data)
                        await send(.internal(.textExtracted(rawText)))
                    } catch {
                        await send(.internal(.extractionFailed(error.localizedDescription, .ocr)))
                    }
                }
                .cancellable(id: CancelID.ocr, cancelInFlight: true)

            case let .internal(.textExtracted(rawText)):
                state.extractedText = rawText
                state.viewState = .textReady
                return .none

            case let .internal(.parsingCompleted(workout)):
                state.extractedWorkout = workout

                guard !workout.sections.isEmpty else {
                    state.failedStage = .parsing
                    state.viewState = .failed(String(localized: "No workout plan found in this text."))
                    return .none
                }

                // Auto-navigate to preview after successful parsing
                state.workoutPreview = WorkoutPreviewFeature.State(
                    trainingSession: workout.toTrainingSession(scanDate: date.now)
                )

                return .none

            case let .internal(.extractionFailed(error, stage)):
                state.failedStage = stage
                state.viewState = .failed(error)
                return .none

                // MARK: - API Key Entry

            case .apiKeyEntry(.presented(.delegate(.keySaved))):
                state.apiKeyEntry = nil
                return .run { send in
                    await send(.view(.continueButtonTapped))
                }

            case .apiKeyEntry(.presented(.delegate(.keyDeleted))):
                state.apiKeyEntry = nil
                return .none

            case .apiKeyEntry:
                return .none

                // MARK: - Workout Preview

            case .workoutPreview(.presented(.view(.editButtonTapped))):
                // Handled internally by WorkoutPreviewFeature (opens editor).
                return .none

            case .workoutPreview(.presented(.delegate(.saved(let session)))):
                return .send(.delegate(.saved(session)))

            case .workoutPreview(.dismiss):
                // Back from preview keeps the OCR text — the user may only
                // want to tweak it and re-parse, not redo the whole scan.
                state.extractedWorkout = nil
                state.viewState = .textReady
                return .none

            case .workoutPreview:
                return .none

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$workoutPreview, action: \.workoutPreview) {
            WorkoutPreviewFeature()
        }
        .ifLet(\.$apiKeyEntry, action: \.apiKeyEntry) {
            APIKeyEntryFeature()
        }
    }

    // MARK: - Helpers

    /// Full reset to the initial screen, killing any in-flight effect so a
    /// late OCR/parse result cannot resurrect the state it belonged to.
    private func resetToIdle(_ state: inout State) -> Effect<Action> {
        // Also drop the picker item — with a stale value, re-picking the SAME
        // photo is a no-op (`onChange` never fires for an equal value).
        state.selectedItem = nil
        state.selectedImageData = nil
        state.extractedText = ""
        state.extractedWorkout = nil
        state.failedStage = nil
        state.viewState = .idle
        return .merge(
            .cancel(id: CancelID.photoLoad),
            .cancel(id: CancelID.ocr),
            .cancel(id: CancelID.parse)
        )
    }

}
