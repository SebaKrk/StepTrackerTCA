//
//  ScanPlanClient.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 07/02/2026.
//

import ComposableArchitecture
import Dependencies
import Foundation
import HealthHub

/// Client responsible for OCR text recognition from images.
struct ScanPlanClient: Sendable {

    /// Recognizes text from raw image data using Vision OCR.
    var recognizeText: @Sendable (_ imageData: Data) async throws -> String
}

extension DependencyValues {
    var scanPlanClient: ScanPlanClient {
        get { self[ScanPlanClient.self] }
        set { self[ScanPlanClient.self] = newValue }
    }
}

extension ScanPlanClient: DependencyKey {

    // MARK: - Live Value

    /// `static let` with closure ensures a single `ScanPlanService` instance (singleton)
    /// for the entire app lifetime. The service is an implementation detail — not a dependency.
    /// To reuse OCR in another reducer: `@Dependency(\.scanPlanClient)`.
    /// To reuse in another client: `@Dependency(\.scanPlanClient)` inside its `liveValue`.
    static let liveValue: ScanPlanClient = {
        let service = ScanPlanService()

        return ScanPlanClient(
            recognizeText: { imageData in
                try await service.recognizeText(from: imageData)
            }
        )
    }()

    // MARK: - Test Value

    static var testValue: ScanPlanClient {
        ScanPlanClient(
            recognizeText: unimplemented("ScanPlanClient.recognizeText")
        )
    }

    // MARK: - Preview Value

    static var previewValue: ScanPlanClient {
        ScanPlanClient(
            recognizeText: { _ in
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
