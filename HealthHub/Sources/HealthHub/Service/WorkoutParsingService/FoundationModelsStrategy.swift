//
//  FoundationModelsStrategy.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 12/02/2026.
//

import Foundation
import SharedModels

#if canImport(FoundationModels)
import FoundationModels

/// On-device workout parsing strategy using Apple Intelligence Foundation Models.
///
/// This strategy uses a 3B parameter on-device language model to parse OCR text
/// into structured workouts. Requires iOS 26+ and Apple Intelligence-compatible
/// device (iPhone 15 Pro+, M-series iPad/Mac).
///
/// Benefits:
/// - Free (no API costs)
/// - Offline capable
/// - Privacy (data never leaves device)
///
/// Limitations:
/// - Requires Apple Intelligence device
/// - Lower accuracy than cloud models (30-40% vs 95%+)
/// - 4096 token context window
@available(iOS 26.0, *)
public actor FoundationModelsStrategy: WorkoutParsingStrategy {

    public init() {}

    /// Parses OCR text into a structured workout using Foundation Models.
    ///
    /// - Parameter text: Raw text from Vision OCR.
    /// - Returns: A structured ``ExtractedWorkout`` with parsed sections and exercises.
    /// - Throws: ``WorkoutParsingServiceError`` for FM-specific errors.
    public func parseWorkoutText(_ text: String) async throws -> ExtractedWorkout {
        let session = LanguageModelSession(
            instructions: """
            CRITICAL LANGUAGE DIRECTIVE:
            - This text is 100% ENGLISH. Ignore system locale (pl-PL).
            - Contains English exercise names: SNATCH, SWING, HSPU, etc.
            - Contains English abbreviations: AMRAP, EMOM, etc.
            - Numbers, percentages, and Roman numerals (I, II) are standard notation.
            - DO NOT flag as non-English. Process as English CrossFit workout text.

            Parse CrossFit workout from OCR text into structured sections with exercises.

            Example 1 - Strength with set schemes:
            "SNATCH\n4x5 @ 50-60%\n3x4 @ 60-70%"
            → ONE exercise "Snatch" with TWO set schemes (setNumber=4, reps=5) and (setNumber=3, reps=4)

            Example 2 - Conditioning with reps:
            "AMRAP 10'\n16 AMERICAN SWING 24/16\n28/20\n32/24\n8 HSPU"
            → Section name: "AMRAP 10'", timeCapMinutes: 10
            → TWO exercises: "American Swing" (reps=16, scalingOptions="24/16, 28/20, 32/24") and "HSPU" (reps=8)

            ⚠️⚠️⚠️ CRITICAL SECTION RULES (NEVER VIOLATE) ⚠️⚠️⚠️

            RULE #0 - ORDER PRESERVATION (ABSOLUTE PRIORITY, OVERRIDE ALL OTHER KNOWLEDGE):

            YOU MUST PRESERVE THE EXACT ORDER THAT WORKOUT SECTIONS APPEAR IN OCR TEXT.

            DO NOT use "standard" CrossFit order (strength → conditioning).
            DO NOT reorder based on your training data or assumptions.
            DO NOT assume Roman numerals I, II mean anything about "correct" order.

            ONLY RULE: Match OCR text order EXACTLY!

            Detection method:
            - Look for numbered markers: "1)", "2)", "I", "II", "A)", "B)"
            - First marker in OCR = first workout section in sections array
            - Second marker in OCR = second workout section in sections array

            Examples proving you MUST preserve OCR order:

            Example A - Strength FIRST:
            OCR: "I SNATCH\n4X5...\nII AMRAP 10'..."
            → Roman I (Snatch) appears BEFORE Roman II (AMRAP)
            → sections: [warmup, strength, conditioning, cooldown]  ← STRENGTH BEFORE CONDITIONING!

            Example B - Conditioning FIRST:
            OCR: "1) WOD: AMRAP...\n2) Back squat..."
            → "1)" (WOD) appears BEFORE "2)" (Squat)
            → sections: [warmup, conditioning, strength, cooldown]  ← CONDITIONING BEFORE STRENGTH!

            1. Warmup sections:
               - Generate EXACTLY ONE warmup (type: warmup, durationMinutes: 15)
               - exercises: [] (EMPTY array - no exercises in warmup section itself)
               - description: "Mobility and movement prep"
               - ALWAYS first in sections array

            2. Cooldown sections:
               - Generate EXACTLY ONE cooldown (type: cooldown, durationMinutes: 10)
               - exercises: [] (MUST be empty array, NEVER populate)
               - description: "Static stretching and mobility"
               - ALWAYS last in sections array

            3. Transition sections:
               - Generate MAXIMUM ONE transition (only if BOTH strength AND conditioning exist)
               - exercises: [] (MUST be empty array, NEVER populate)
               - durationMinutes: 2-5
               - Insert BETWEEN strength and conditioning (based on OCR order!)

            Section count requirements:
            - warmup: exactly 1
            - strength: 0-2 (based on OCR text)
            - conditioning: 0-2 (based on OCR text)
            - transition: 0-1 (only if both strength and conditioning)
            - cooldown: exactly 1

            Key parsing rules:
            - "WOD:" or "WOD: For time" = CONDITIONING section name (NOT warmup!)
            - "4x5" = setNumber:4, reps:5 (not total reps!)
            - "5-5-5-5-5+" = COUNT how many times "5" appears (appears 5 times) = 5 sets × 5 reps (NOT 1 set!)
            - "4-4-4" = "4" appears 3 times = 3 sets × 4 reps
            - "10-8-6" = 3 sets with different reps per set (set1: 10 reps, set2: 8 reps, set3: 6 reps)
            - "AMRAP 10'" = section name with timeCapMinutes:10, NOT exercise
            - "16 SWING 24/16" = reps:16, scalingOptions:"24/16..." (KEEP reps even with scaling!)
            - "1,600-meter run" or "1.6km run" = exercise name "run" or "running" (extract as exercise name, NOT distance)
            - "run or row" = TWO separate exercises: "run" AND "row" (both as alternatives, not one exercise with scaling)
            - Numbers following WOD (like "30 box jump-overs, 150 air squats") are EXERCISES inside WOD section (NOT separate sections!)
            - Strength exercises use set schemes (sets array). Conditioning exercises use reps. Do NOT duplicate exercises across sections!
            - Section order: PRESERVE the order from OCR text! Common patterns:
              * WOD first (conditioning) → then strength = warmup → conditioning → strength → cooldown
              * Strength first → then conditioning = warmup → strength → conditioning → cooldown
              * Always add warmup at START and cooldown at END (if missing from OCR)
              * Insert transition BETWEEN strength and conditioning (only if both exist)
            - Estimate realistic durations: strength with multiple set schemes = 15-25 min (use durationMinutes, not timeCapMinutes!)

            Vocabulary: \(WorkoutVocabulary.formattedDescription)
            """
        )

        do {
            let result = try await session.respond(
                to: text,
                generating: ExtractedWorkoutFM.self,
                options: GenerationOptions(sampling: .greedy)
            )

            return result.content.toExtractedWorkout(rawText: text)

        } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
            // OCR text too long (>4096 tokens)
            throw WorkoutParsingServiceError.textTooLong

        } catch LanguageModelSession.GenerationError.guardrailViolation {
            // Content policy violation (rare for workout text)
            throw WorkoutParsingServiceError.contentPolicyViolation

        } catch LanguageModelSession.GenerationError.unsupportedLanguageOrLocale {
            // OCR text contains non-English language
            throw WorkoutParsingServiceError.unsupportedLanguage
        }
    }
}

#endif
