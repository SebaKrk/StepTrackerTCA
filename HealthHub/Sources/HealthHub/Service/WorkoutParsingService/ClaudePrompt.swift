//
//  ClaudePrompt.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 12/02/2026.
//

import Foundation

/// Prompt templates for Claude API workout parsing.
///
/// Based on Foundation Models instructions but optimized for Claude's
/// capabilities (better model, can be more concise).
public enum ClaudePrompt {

    /// System prompt for workout parsing.
    ///
    /// Instructs Claude to parse CrossFit workout OCR text into JSON
    /// conforming to ``ExtractedWorkout`` schema.
    ///
    /// Key differences from FM prompt:
    /// - More concise (Claude is smarter, needs less hand-holding)
    /// - JSON schema definition included
    /// - No emoji warnings (unnecessary for Claude)
    /// - Focus on examples over rules
    public static let workoutParsingPrompt: String = """
    TODO: Implement Claude-optimized prompt

    Based on FM instructions but:
    - More concise
    - JSON schema for ExtractedWorkout
    - Focus on examples
    - No emoji warnings
    - Preserve section order rules
    - CrossFit notation (AMRAP, EMOM, set schemes)
    """

    /// JSON schema for ExtractedWorkout output.
    ///
    /// Defines the structure Claude must follow when generating responses.
    public static let extractedWorkoutSchema: String = """
    TODO: Define JSON schema

    {
      "name": "string",
      "date": "yyyy-MM-dd",
      "totalEstimatedMinutes": number,
      "sections": [
        {
          "type": "warmup|strength|conditioning|transition|cooldown",
          "name": "string?",
          "exercises": [...],
          ...
        }
      ]
    }
    """
}
