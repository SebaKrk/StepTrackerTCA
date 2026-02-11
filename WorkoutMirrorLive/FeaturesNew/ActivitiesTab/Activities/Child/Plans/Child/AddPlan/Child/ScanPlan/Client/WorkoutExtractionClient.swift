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

/// Client responsible for extracting workout text from images.
///
/// The extraction strategy is determined at runtime by device capabilities:
/// - **On-device** (iPhone 15 Pro+, M-series): Vision OCR → Foundation Models (free)
/// - **Cloud** (older devices): Claude API with image analysis (paid)
///
/// Both strategies return the same `String` output — the feature layer
/// is unaware of which backend is used.
struct WorkoutExtractionClient: Sendable {

    /// Extracts workout text from raw image data.
    /// Strategy (OCR+FM vs Claude API) is determined by device capabilities.
    var extractWorkout: @Sendable (_ imageData: Data) async throws -> String
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
        if FoundationModelAvailability.isAvailable {
            // On-device strategy: OCR → Foundation Models (free)
            let ocrService = ScanPlanService()
            // TODO: Add FoundationModelService for text → TrainingSession parsing
            return WorkoutExtractionClient(
                extractWorkout: { imageData in
                    try await ocrService.recognizeText(from: imageData)
                }
            )
        } else {
            // Cloud strategy: Claude API (paid)
            // TODO: Replace OCR fallback with ClaudeAPIService when implemented
            let ocrService = ScanPlanService()
            return WorkoutExtractionClient(
                extractWorkout: { imageData in
                    try await ocrService.recognizeText(from: imageData)
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
                """
                Bench Press 4x8 80kg
                Squat 5x5 100kg
                Deadlift 3x5 120kg
                Overhead Press 3x8 50kg
                Barbell Row 4x8 70kg
                """
            }
        )
    }
}
