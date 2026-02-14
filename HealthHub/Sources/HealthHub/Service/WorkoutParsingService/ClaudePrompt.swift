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

    CrossFit notation:
    - "4x5" = 4 sets × 5 reps (setNumber: 4, reps: 5)
    - "5-5-5-5-5" = count occurrences → 5 sets × 5 reps
    - "AMRAP 10'" = timeCapMinutes: 10
    - "24/16" in exercises = scalingOptions for M/F weights

    Return ONLY valid JSON matching this schema:

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
