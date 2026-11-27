//
//  WorkoutExtractionClient.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 09/02/2026.
//

import ComposableArchitecture
import Dependencies
import Foundation
import HealthHub
import SharedModels

/// Client responsible for extracting text and parsing workouts from images.
///
/// Pipeline: Image → Vision OCR → Text → chosen ``WorkoutParsingBackend`` → ScannedBoard
struct WorkoutExtractionClient: Sendable {

    /// Extracts raw text from image using Vision OCR.
    var extractText: @Sendable (_ imageData: Data) async throws -> String

    /// Parses a scan (photo + OCR text) into a structured workout with the chosen backend.
    var parseWorkout: @Sendable (
        _ input: WorkoutScanInput,
        _ backend: WorkoutParsingBackend
    ) async throws -> ScannedBoard

    /// Sends the plan chat so far; the reply carries a corrected board once the user confirmed.
    var refinePlan: @Sendable (
        _ board: ScannedBoard,
        _ findings: [String],
        _ messages: [PlanChatMessage]
    ) async throws -> PlanRefinement
}

extension DependencyValues {
    nonisolated var workoutExtractionClient: WorkoutExtractionClient {
        get { self[WorkoutExtractionClient.self] }
        set { self[WorkoutExtractionClient.self] = newValue }
    }
}

extension WorkoutExtractionClient: DependencyKey {

    // MARK: - Live Value

    /// Production client using Vision OCR + the backend picked in settings.
    ///
    /// The parsing call goes through ``ScanProxy``: the API key lives in the
    /// deployed function, so nothing here reads or holds one.
    nonisolated static let liveValue: WorkoutExtractionClient = {

        let ocrService = ScanPlanService()

        return WorkoutExtractionClient(
            extractText: { imageData in
                try await ocrService.recognizeText(from: imageData)
            },
            parseWorkout: { input, backend in
                @Dependency(\.date) var date
                #if DEBUG
                print("🧭 [WorkoutExtractionClient] backend=\(backend.rawValue) image=\(input.imageData?.count ?? 0) bytes text=\(input.ocrText.count) chars")
                #endif
                let strategy = WorkoutParsingStrategyFactory.make(backend, proxy: ScanProxy.shared)
                #if DEBUG
                let recorder = ScanRunRecorder()
                let startedAt = date.now
                do {
                    let board = try await strategy.parseWorkout(input)
                    await recorder.record(
                        input,
                        backend: backend,
                        outcome: .success(board),
                        startedAt: startedAt,
                        finishedAt: date.now
                    )
                    return board
                } catch {
                    await recorder.record(
                        input,
                        backend: backend,
                        outcome: .failure(String(describing: error)),
                        startedAt: startedAt,
                        finishedAt: date.now
                    )
                    throw error
                }
                #else
                return try await strategy.parseWorkout(input)
                #endif
            },
            refinePlan: { board, findings, messages in
                try await ScanProxy.shared.refinePlan(
                    board: board,
                    findings: findings,
                    messages: messages,
                    language: ScanLanguage.preferredName()
                )
            }
        )
    }()

    // MARK: - Test Value

    nonisolated static var testValue: WorkoutExtractionClient {
        WorkoutExtractionClient(
            extractText: unimplemented("WorkoutExtractionClient.extractText"),
            parseWorkout: unimplemented("WorkoutExtractionClient.parseWorkout"),
            refinePlan: unimplemented("WorkoutExtractionClient.refinePlan")
        )
    }

    // MARK: - Preview Value

    nonisolated static var previewValue: WorkoutExtractionClient {
        WorkoutExtractionClient(
            extractText: { _ in
                """
                Bench Press 4x8 80kg
                Squat 5x5 100kg
                Deadlift 3x5 120kg
                """
            },
            parseWorkout: { _, _ in
                ScannedBoard(
                    boardKind: .strengthDay,
                    title: "Preview Workout",
                    activity: WorkoutActivityType.strengthTraining.rawValue,
                    sections: [
                        ScannedSection(
                            kind: .strength,
                            name: "Bench Press + Squat + Deadlift",
                            movements: [
                                ScannedMovement(name: "bench press", sets: [ScannedSet(value: 8, load: 80, loadUnit: .kg)]),
                                ScannedMovement(name: "back squat", sets: [ScannedSet(value: 5, load: 100, loadUnit: .kg)]),
                                ScannedMovement(name: "deadlift", sets: [ScannedSet(value: 5, load: 120, loadUnit: .kg)]),
                            ]
                        ),
                    ]
                )
            },
            refinePlan: { _, _, _ in
                PlanRefinement(
                    reply: "So WOD 2 is a descending ladder 15-12-9-6-3, for time — is that right?",
                    board: nil,
                    changes: []
                )
            }
        )
    }
}
