//
//  WorkoutParsingService.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 11/02/2026.
//

import Foundation
import SharedModels

#if canImport(FoundationModels)
import FoundationModels

/// Parses raw OCR text into a structured ``ExtractedWorkout`` using on-device Foundation Models.
///
/// The service creates a ``LanguageModelSession`` with CrossFit-specific instructions
/// and uses `@Generable` schema to produce structured output. Beyond parsing,
/// the model enriches the data with AI-generated warmup, cooldown, transitions,
/// scaling options, and estimated duration.
@available(iOS 26.0, *)
public actor WorkoutParsingService {

    public init() {}

    /// Parses OCR text into a structured workout.
    ///
    /// - Parameter text: Raw text from Vision OCR.
    /// - Returns: A fully structured ``ExtractedWorkout`` with AI-generated enrichments.
    /// - Throws: ``WorkoutParsingServiceError`` or Foundation Models errors.
    public func parseWorkoutText(_ text: String) async throws -> ExtractedWorkout {
        let session = LanguageModelSession(
            instructions: """
            You are a CrossFit workout parser.
            Parse OCR text into a structured workout plan.

            Rules:
            - Generate a descriptive workout name. Fallback: "CrossFit" + date
            - Always include warmup (based on exercises) and cooldown
            - Add transition sections between workout parts (if ≥2 parts)
            - Suggest scaling options for exercises
            - Estimate total duration
            - Extract ONLY exercises visible in the text
            - Use today's date if not specified

            Vocabulary:
            \(WorkoutVocabulary.formattedDescription)
            """
        )

        let result = try await session.respond(
            to: text,
            generating: ExtractedWorkoutFM.self
        )

        return result.content.toExtractedWorkout(rawText: text)
    }
}

#endif
