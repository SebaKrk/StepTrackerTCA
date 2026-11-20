//
//  WorkoutParsingStrategy.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 12/02/2026.
//

import Foundation
import SharedModels

/// Protocol defining a strategy for parsing a scanned board into a ``ScannedBoard``.
///
/// Backends are picked by ``WorkoutParsingBackend`` through ``WorkoutParsingStrategyFactory``.
/// Text-only backends implement ``parseWorkoutText(_:)`` and inherit the default
/// ``parseWorkout(_:)``; image-capable backends override ``parseWorkout(_:)``.
public protocol WorkoutParsingStrategy: Sendable {

    /// Parses a scan (photo and/or OCR text) into a structured workout.
    ///
    /// - Parameter input: The photo and the OCR text the scan produced.
    /// - Returns: The board as the model read it, in board order.
    /// - Throws: Strategy-specific errors (e.g., network failures, model unavailability).
    func parseWorkout(_ input: WorkoutScanInput) async throws -> ScannedBoard

    /// Parses raw OCR text into a structured workout.
    ///
    /// - Parameter text: Raw text recognized by Vision OCR from a workout photo.
    /// - Returns: The board as the model read it, in board order.
    /// - Throws: Strategy-specific errors (e.g., network failures, model unavailability).
    func parseWorkoutText(_ text: String) async throws -> ScannedBoard
}

public extension WorkoutParsingStrategy {

    /// Text-only backends keep working untouched: the image is simply not read.
    func parseWorkout(_ input: WorkoutScanInput) async throws -> ScannedBoard {
        try await parseWorkoutText(input.ocrText)
    }
}
