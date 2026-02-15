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

/// Client responsible for extracting a structured workout from images.
///
/// Pipeline: Image → Vision OCR → Parsing Strategy → ExtractedWorkout
///
/// Parsing strategy (Foundation Models vs Claude API) is selected in
/// ``WorkoutParsingClient.liveValue`` — feature layer is unaware of implementation.
struct WorkoutExtractionClient: Sendable {

    /// Extracts a structured workout from raw image data.
    /// Strategy (OCR+FM vs OCR-only fallback) is determined by device capabilities.
    var extractWorkout: @Sendable (_ imageData: Data) async throws -> ExtractedWorkout
}

extension DependencyValues {
    var workoutExtractionClient: WorkoutExtractionClient {
        get { self[WorkoutExtractionClient.self] }
        set { self[WorkoutExtractionClient.self] = newValue }
    }
}

extension WorkoutExtractionClient: DependencyKey {

    // MARK: - Live Value

    /// Production client using Vision OCR + selected parsing strategy.
    ///
    /// Parsing strategy is determined by ``WorkoutParsingClient.liveValue``:
    /// - `.claude` → Claude API (current selection)
    /// - `.foundationModels` → On-device Foundation Models
    static let liveValue: WorkoutExtractionClient = WorkoutExtractionClient(
        extractWorkout: { imageData in
            @Dependency(\.workoutParsingClient) var parsingClient
            let ocrService = ScanPlanService()

            // Step 1: OCR (Vision framework)
            let rawText = try await ocrService.recognizeText(from: imageData)

            // Step 2: Parsing (strategy selected in WorkoutParsingClient)
            return try await parsingClient.parseWorkout(rawText)
        }
    )

    // MARK: - Test Value

    static var testValue: WorkoutExtractionClient {
        WorkoutExtractionClient(
            extractWorkout: unimplemented("WorkoutExtractionClient.extractWorkout")
        )
    }

    // MARK: - Preview Value

    static var previewValue: WorkoutExtractionClient {
        WorkoutExtractionClient(
            extractWorkout: { _ in
                ExtractedWorkout(
                    name: "Preview Workout",
                    date: "2026-02-11",
                    totalEstimatedMinutes: 45,
                    rawText: """
                    Bench Press 4x8 80kg
                    Squat 5x5 100kg
                    Deadlift 3x5 120kg
                    """,
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
