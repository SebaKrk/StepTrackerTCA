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
/// Pipeline: Image → Vision OCR → Text → chosen ``WorkoutParsingBackend`` → ExtractedWorkout
struct WorkoutExtractionClient: Sendable {

    /// Extracts raw text from image using Vision OCR.
    var extractText: @Sendable (_ imageData: Data) async throws -> String

    /// Parses a scan (photo + OCR text) into a structured workout with the chosen backend.
    var parseWorkout: @Sendable (
        _ input: WorkoutScanInput,
        _ backend: WorkoutParsingBackend
    ) async throws -> ExtractedWorkout
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
    /// API key is read at call-time from Keychain via ``APIKeyClient``.
    nonisolated static let liveValue: WorkoutExtractionClient = {
        
        let ocrService = ScanPlanService()
        
        return WorkoutExtractionClient(
            extractText: { imageData in
                try await ocrService.recognizeText(from: imageData)
            },
            parseWorkout: { input, backend in
                @Dependency(\.apiKeyClient) var apiKeyClient
                #if DEBUG
                print("🧭 [WorkoutExtractionClient] backend=\(backend.rawValue) image=\(input.imageData?.count ?? 0) bytes text=\(input.ocrText.count) chars")
                #endif
                let strategy = WorkoutParsingStrategyFactory.make(backend, apiKey: apiKeyClient.load())
                return try await strategy.parseWorkout(input)
            }
        )
    }()

    // MARK: - Test Value

    nonisolated static var testValue: WorkoutExtractionClient {
        WorkoutExtractionClient(
            extractText: unimplemented("WorkoutExtractionClient.extractText"),
            parseWorkout: unimplemented("WorkoutExtractionClient.parseWorkout")
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
                ExtractedWorkout(
                    name: "Preview Workout",
                    date: "2026-02-11",
                    totalEstimatedMinutes: 45,
                    sections: [
                        WorkoutSection(
                            type: .warmup,
                            durationMinutes: 10,
                            description: "General warmup and mobility"
                        ),
                        WorkoutSection(
                            type: .strength,
                            name: "Bench Press + Squat + Deadlift",
                            exercises: [
                                ExtractedExercise(name: "Bench Press", sets: [
                                    ExerciseSet(setNumber: 1, reps: 8, intensity: "80kg"),
                                ]),
                                ExtractedExercise(name: "Squat", sets: [
                                    ExerciseSet(setNumber: 1, reps: 5, intensity: "100kg"),
                                ]),
                                ExtractedExercise(name: "Deadlift", sets: [
                                    ExerciseSet(setNumber: 1, reps: 5, intensity: "120kg"),
                                ]),
                            ]
                        ),
                        WorkoutSection(
                            type: .cooldown,
                            durationMinutes: 5,
                            description: "Stretching and mobility"
                        ),
                    ]
                )
            }
        )
    }
}
