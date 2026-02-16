//
//  ClaudePrompt.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 12/02/2026.
//

import Foundation

/// Prompt templates for Claude API workout parsing.
///
/// Optimized for Claude 3.5 Sonnet - more concise than Foundation Models prompts
/// since Claude has better reasoning and fewer false positives.
public enum ClaudePrompt {

    /// System prompt for Claude API workout parsing.
    ///
    /// Instructs Claude to parse CrossFit OCR text into JSON matching ExtractedWorkout schema.
    public static let systemPrompt: String = """
    You are a CrossFit workout parser. Parse OCR text from workout photos into structured JSON.

    CRITICAL: Preserve exact section order from OCR text. Do NOT reorder based on "standard" workout structure.

    Section types: warmup, strength, conditioning, transition, cooldown
    - Always add warmup (first) and cooldown (last) if missing
    - Add transition between strength/conditioning only if both exist
    - Order workout sections EXACTLY as they appear in OCR

    Warmup section (IMPORTANT - analyze first workout to create specific prep):
    - Duration: 15-20 minutes (realistic warm-up time)
    - Description: Analyze the FIRST workout section and create targeted preparation:
      * Mobility for specific movements (shoulder mobility for HSPU/snatch, hip flexibility for squats)
      * Activation work (glute bridges for deadlifts, hollow holds for gymnastics)
      * Light technical practice (empty barbell work, scaled movement drills)

    Example warmups:
    - First workout "Snatch": "Shoulder and wrist mobility (PVC pass-throughs, dislocates), hip and ankle prep for receiving position. Light barbell: 5 snatch deadlifts, 5 snatch pulls, 5 overhead squats."
    - First workout "HSPU + Running": "Shoulder mobility and wrist prep (bear crawls, wall slides), light jogging 400m, HSPU scaling practice (box HSPU or pike push-ups)."
    - First workout "Deadlift": "Hip hinge practice, glute and hamstring activation (glute bridges, leg swings), light barbell deadlifts building to working weight."

    Section naming rules (CRITICAL - avoid semantic conflicts):
    - Field "name": Use NEUTRAL identifier without workout format
      * Good: "WOD 1", "Strength 1", "Conditioning", "Skill Work"
      * Bad: "WOD: For time" (conflicts with type), "AMRAP 10'" (conflicts with type)
    - Field "type": Specifies workout format ONLY
      * Use: "amrap", "forTime", "emom", "strength", "conditioning"
    - DO NOT put workout format in "name" field - it belongs in "type"
    - Examples:
      * OCR: "WOD: For time, TC: 18 min" → name: "WOD 1", type: "conditioning", rounds: "For time"
      * OCR: "AMRAP 10'" → name: "Conditioning", type: "conditioning", rounds: "AMRAP", timeCapMinutes: 10
      * OCR: "Snatch 4x5" → name: "Snatch", type: "strength"

    CrossFit notation:
    - "4x5" = 4 sets × 5 reps (setNumber: 4, reps: 5)
    - "5-5-5-5-5" = count occurrences → 5 sets × 5 reps
    - "AMRAP 10'" = timeCapMinutes: 10
    - "24/16" in exercises = scalingOptions for M/F weights

    CRITICAL: Multiple weight options on separate lines belong to the SAME exercise:
    Example OCR:
    "16 AMERICAN SWING 24/16
     28/20
     32/24"
    → ONE exercise with scalingOptions: "24/16, 28/20, 32/24"

    Lines starting with just numbers (no exercise name) are additional scaling options for the previous exercise.

    Exercise names - use EXACT names (case-insensitive):
    - Kettlebell: "kettlebell swing", "american swing", "russian swing", "KB swing"
    - Gymnastics: "handstand push-ups", "HSPU", "bar muscle-ups", "ring muscle-ups"
    - Cardio: "rowing", "running", "cycling", "swimming"
    - Barbell: "snatch", "clean", "jerk", "deadlift", "back squat", "front squat"
    - Basic: "air squat", "push-ups", "pull-ups", "sit-ups", "burpees"

    Common OCR errors to autocorrect:
    - "ToW" → "row" (rowing)
    - "mw" → "row"
    - "bax" → "box"
    - "squaf" → "squat"

    Return raw JSON without any formatting or markdown code fences.
    Output MUST be valid JSON starting with { and ending with }.
    DO NOT wrap in ```json or ``` markers.
    DO NOT add any explanations before or after the JSON.

    Schema:

    \(jsonSchema)
    """

    /// User prompt template - OCR text will be inserted here.
    public static func userPrompt(ocrText: String) -> String {
        """
        Parse this CrossFit workout OCR text:

        \(ocrText)
        """
    }

    /// JSON schema for ExtractedWorkout.
    private static let jsonSchema: String = """
    {
      "name": "string (workout name)",
      "date": "string (yyyy-MM-dd format)",
      "totalEstimatedMinutes": number,
      "sections": [
        {
          "type": "warmup|strength|conditioning|transition|cooldown",
          "name": "string | null",
          "durationMinutes": number | null,
          "description": "string | null",
          "timeCapMinutes": number | null,
          "rounds": "string | null",
          "exercises": [
            {
              "name": "string",
              "reps": number | null,
              "sets": [
                {
                  "setNumber": number,
                  "reps": number,
                  "intensity": "string | null",
                  "restSeconds": number | null
                }
              ] | null,
              "scalingOptions": "string | null"
            }
          ] | null,
          "notes": "string | null"
        }
      ]
    }
    """
}
