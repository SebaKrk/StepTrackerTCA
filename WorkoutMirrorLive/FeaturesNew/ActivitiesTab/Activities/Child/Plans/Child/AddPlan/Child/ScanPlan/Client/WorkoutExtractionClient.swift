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
/// The extraction strategy is determined at runtime by device capabilities:
/// - **On-device** (iPhone 15 Pro+, M-series): Vision OCR → Foundation Models (free)
/// - **Cloud** (older devices): Vision OCR → fallback with raw text only
///
/// Both strategies return ``ExtractedWorkout`` — the feature layer
/// is unaware of which backend is used.
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

    /// Singleton — strategy is selected once at startup based on device capabilities.
    static let liveValue: WorkoutExtractionClient = {
        let ocrService = ScanPlanService()

        if FoundationModelAvailability.isAvailable {
            // On-device strategy: OCR → Foundation Models (free)
            return WorkoutExtractionClient(
                extractWorkout: { imageData in
                    let rawText = try await ocrService.recognizeText(from: imageData)

                    #if canImport(FoundationModels)
                    if #available(iOS 26.0, *) {
                        let parsingService = WorkoutParsingService()
                        let result = try await parsingService.parseWorkoutText(rawText)
                        print("[WorkoutExtractionClient] FM parsing completed: \(result.name), \(result.sections.count) sections")
                        return result
                    }
                    #endif

                    throw WorkoutParsingServiceError.foundationModelsUnavailable
                }
            )
        } else {
            // Cloud strategy: OCR only (FM unavailable)
            // TODO: Replace with ClaudeAPIService when implemented
            return WorkoutExtractionClient(
                extractWorkout: { imageData in
                    let rawText = try await ocrService.recognizeText(from: imageData)
                    return ExtractedWorkout(
                        name: "CrossFit",
                        date: "",
                        totalEstimatedMinutes: 0,
                        rawText: rawText,
                        sections: []
                    )
                }
            )
        }
    }()

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
