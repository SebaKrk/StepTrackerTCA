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
/// Pipeline: Image → Vision OCR → Text → Parsing Strategy → ExtractedWorkout
///
/// Parsing strategy (Foundation Models vs Claude API) is selected in
/// ``WorkoutParsingClient.liveValue`` — feature layer is unaware of implementation.
struct WorkoutExtractionClient: Sendable {

    /// Extracts raw text from image using Vision OCR.
    var extractText: @Sendable (_ imageData: Data) async throws -> String

    /// Parses raw OCR text into structured workout.
    var parseWorkout: @Sendable (_ rawText: String) async throws -> ExtractedWorkout
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
        extractText: { imageData in
            let ocrService = ScanPlanService()
            return try await ocrService.recognizeText(from: imageData)
        },
        parseWorkout: { rawText in
            @Dependency(\.workoutParsingClient) var parsingClient
            return try await parsingClient.parseWorkout(rawText)
        }
    )

    // MARK: - Test Value

    static var testValue: WorkoutExtractionClient {
        WorkoutExtractionClient(
            extractText: unimplemented("WorkoutExtractionClient.extractText"),
            parseWorkout: unimplemented("WorkoutExtractionClient.parseWorkout")
        )
    }

    // MARK: - Preview Value

    static var previewValue: WorkoutExtractionClient {
        WorkoutExtractionClient(
            extractText: { _ in
                """
                Bench Press 4x8 80kg
                Squat 5x5 100kg
                Deadlift 3x5 120kg
                """
            },
            parseWorkout: { rawText in
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
