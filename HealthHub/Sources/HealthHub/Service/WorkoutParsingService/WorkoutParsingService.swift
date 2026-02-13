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
/// and uses `@Generable` schema to produce structured output. The model extracts
/// workout sections, exercises, sets, reps, and weights EXACTLY as they appear
/// in the OCR text, without adding or enriching content.
@available(iOS 26.0, *)
public actor WorkoutParsingService {

    public init() {}

    /// Parses OCR text into a structured workout.
    ///
    /// - Parameter text: Raw text from Vision OCR.
    /// - Returns: A structured ``ExtractedWorkout`` with parsed sections and exercises.
    /// - Throws: ``WorkoutParsingServiceError`` or Foundation Models errors.
    public func parseWorkoutText(_ text: String) async throws -> ExtractedWorkout {
        let session = LanguageModelSession(
            instructions: """
            Parse CrossFit workout from OCR text into structured sections with exercises.

            Example 1 - Strength with set schemes:
            "SNATCH\n4x5 @ 50-60%\n3x4 @ 60-70%"
            → ONE exercise "Snatch" with TWO set schemes (setNumber=4, reps=5) and (setNumber=3, reps=4)

            Example 2 - Conditioning with reps:
            "AMRAP 10'\n16 AMERICAN SWING 24/16\n28/20\n32/24\n8 HSPU"
            → Section name: "AMRAP 10'", timeCapMinutes: 10
            → TWO exercises: "American Swing" (reps=16, scalingOptions="24/16, 28/20, 32/24") and "HSPU" (reps=8)

            Key rules:
            - "4x5" = setNumber:4, reps:5 (not total reps!)
            - "AMRAP 10'" = section name with timeCapMinutes:10, NOT exercise
            - "16 SWING 24/16" = reps:16, scalingOptions:"24/16..." (KEEP reps even with scaling!)
            - Strength exercises use set schemes (sets array). Conditioning exercises use reps. Do NOT duplicate exercises across sections!
            - Section order: warmup → strength → transition (if both strength and conditioning) → conditioning → cooldown
            - Generate warmup (15 min) if missing: mobility prep (NOT main exercises - light movements only)
            - Insert transition (2-5 min, NO exercises) BETWEEN strength and conditioning sections (not after conditioning!)
            - Generate cooldown (10 min, NO exercises list) if missing: description only "Static stretching and mobility"
            - Estimate realistic durations: strength with multiple set schemes = 15-25 min (use durationMinutes, not timeCapMinutes!)

            Vocabulary: \(WorkoutVocabulary.formattedDescription)
            """
        )

        let result = try await session.respond(
            to: text,
            generating: ExtractedWorkoutFM.self,
            options: GenerationOptions(sampling: .greedy)
        )

        return result.content.toExtractedWorkout(rawText: text)
    }
}

#endif
