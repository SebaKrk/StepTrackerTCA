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
/// Flow: Take/select photo → Load image data → Parse (backend from settings) → Preview.
/// Text backends add Vision OCR in between, and `claudeText` also lets the user edit the
/// text before parsing. Both steps go through ``WorkoutExtractionClient``.
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

    @Dependency(\.date) var date
    @Dependency(\.dismiss) var dismiss
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
                state.viewState = .failed(Self.cameraFailure)
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
                    let data = try? await item.loadTransferable(type: Data.self)
                    await send(.internal(.galleryPhotoLoaded(data)))
                }
                .cancellable(id: CancelID.photoLoad, cancelInFlight: true)

            case .view(.continueButtonTapped):
                guard !state.extractedText.isEmpty else { return .none }
                return startParsing(&state)

            case .view(.retryTapped):
                // Retry re-runs only the failed stage — the picked photo and
                // OCR text are already paid for; a transient network error
                // during parsing must not cost the user that work.
                switch state.failedStage {
                case .parsing where state.selectedImageData != nil || !state.extractedText.isEmpty:
                    return startParsing(&state)

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

            case .view(.addManuallyTapped):
                // Closing this screen lands on Add Plan, where the manual form lives.
                return .run { _ in await dismiss() }

            case let .view(.parsingBackendChanged(backend)):
                state.$parsingBackend.withLock { $0 = backend }
                return .none

                // MARK: - Internal Action

            case let .internal(.galleryPhotoLoaded(data)):
                guard let data else {
                    state.failedStage = .photoLoad
                    state.viewState = .failed(Self.photoLoadFailure)
                    return .none
                }
                // The document camera crops on its own; a library photo gets the same step here.
                state.photoCrop = PhotoCropFeature.State(imageData: data)
                return .none

            case let .internal(.imageLoaded(data)):
                guard let data else {
                    state.failedStage = .photoLoad
                    state.viewState = .failed(Self.photoLoadFailure)
                    return .none
                }
                state.selectedImageData = data
                state.viewState = .analyzing
                state.failedStage = nil
                // The photo backend reads the picture itself — no OCR, no text step.
                guard state.parsingBackend.needsOCRText else { return startParsing(&state) }
                return .run { send in
                    do {
                        let rawText = try await extractionClient.extractText(data)
                        await send(.internal(.textExtracted(rawText)))
                    } catch {
                        await send(.internal(.extractionFailed(ScanProxyError.scanFailure(for: error), .ocr)))
                    }
                }
                .cancellable(id: CancelID.ocr, cancelInFlight: true)

            case let .internal(.textExtracted(rawText)):
                state.extractedText = rawText
                guard state.parsingBackend.showsTextStep else { return startParsing(&state) }
                state.viewState = .textReady
                return .none

            case let .internal(.parsingCompleted(rawBoard)):
                let (board, fixes) = rawBoard.normalized()
                state.extractedWorkout = board
                let session = board.toTrainingSession(scanDate: date.now)

                if let hard = ScanReviewValidator.hardFindings(board: board, plan: session).first {
                    state.failedStage = .parsing
                    state.viewState = .failed(Self.reviewFailure(hard.message))
                    return .none
                }

                // Preview opens right away; the review card and a disabled Save carry the doubts.
                var preview = WorkoutPreviewFeature.State(trainingSession: session)
                preview.scannedSession = session
                preview.boardFindings = IdentifiedArray(
                    uniqueElements: ScanReviewValidator.boardFindings(board: board, fixes: fixes, plan: session)
                )
                preview.planFindings = IdentifiedArray(uniqueElements: ScanReviewValidator.planFindings(session))
                state.workoutPreview = preview
                return .none

            case let .internal(.extractionFailed(error, stage)):
                state.failedStage = stage
                state.viewState = .failed(error)
                return .none

            case .photoCrop(.presented(.delegate(.cropped(let data)))):
                state.photoCrop = nil
                return .send(.internal(.imageLoaded(data)))

            case .photoCrop(.presented(.delegate(.cancelled))), .photoCrop(.dismiss):
                state.photoCrop = nil
                return resetToIdle(&state)

            case .photoCrop:
                return .none

                // MARK: - Workout Preview

            case .workoutPreview(.presented(.view(.editButtonTapped))):
                // Handled internally by WorkoutPreviewFeature (opens editor).
                return .none

            case .workoutPreview(.presented(.delegate(.saved(let session)))):
                return .send(.delegate(.saved(session)))

            case .workoutPreview(.dismiss):
                state.extractedWorkout = nil
                // Back from preview keeps the OCR text — the user may only want
                // to tweak it and re-parse. The photo backends have no transcript,
                // so for them that screen would be an empty editor.
                guard state.parsingBackend.showsTextStep, !state.extractedText.isEmpty else {
                    return resetToIdle(&state)
                }
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
        .ifLet(\.$photoCrop, action: \.photoCrop) {
            PhotoCropFeature()
        }
    }

    // MARK: - Failures

    /// The document scanner itself failed — a different photo usually works.
    nonisolated static let cameraFailure = ScanFailure(
        title: String(localized: "Scanning failed"),
        message: String(localized: "The scanner could not capture the page. Try again."),
        canRetry: true
    )

    /// The picked image could not be read, often an iCloud photo that never downloaded.
    nonisolated static let photoLoadFailure = ScanFailure(
        title: String(localized: "Could not open the photo"),
        message: String(localized: "Pick the photo again, or take a new one."),
        canRetry: false
    )

    /// The board parsed, but the review found something that blocks a usable plan.
    ///
    /// The finding already reads as a full sentence, so it becomes the body.
    nonisolated static func reviewFailure(_ message: String) -> ScanFailure {
        ScanFailure(
            title: String(localized: "The plan could not be read"),
            message: message,
            canRetry: true
        )
    }

    // MARK: - Helpers

    /// Full reset to the initial screen, killing any in-flight effect so a
    /// late OCR/parse result cannot resurrect the state it belonged to.
    /// Sends the photo and text to the chosen backend through the proxy; the daily
    /// allowance is checked server-side, so every entry point behaves the same.
    private func startParsing(_ state: inout State) -> Effect<Action> {
        state.viewState = .analyzing
        state.failedStage = nil
        let input = WorkoutScanInput(imageData: state.selectedImageData, ocrText: state.extractedText)
        return .run { [backend = state.parsingBackend] send in
            do {
                let board = try await extractionClient.parseWorkout(input, backend)
                await send(.internal(.parsingCompleted(board)))
            } catch {
                await send(.internal(.extractionFailed(ScanProxyError.scanFailure(for: error), .parsing)))
            }
        }
        .cancellable(id: CancelID.parse, cancelInFlight: true)
    }

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
