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
            }
        )
    }
}
