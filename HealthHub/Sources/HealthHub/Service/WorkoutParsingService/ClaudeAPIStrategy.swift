//
//  ClaudeAPIStrategy.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 12/02/2026.
//

import Foundation
import SharedModels

/// Cloud-based workout parsing strategy using Claude API.
///
/// This strategy sends OCR text to Claude API for parsing into structured workouts.
///
/// Benefits:
/// - High accuracy (95%+ vs 30-40% for on-device FM)
/// - No device requirements (works on all iOS versions)
/// - Better at complex/ambiguous workout formats
///
/// Limitations:
/// - Requires internet connection
/// - API costs (~$0.016 per workout)
/// - Privacy: data sent to Anthropic servers
public actor ClaudeAPIStrategy: WorkoutParsingStrategy {

    public init() {}

    /// Parses OCR text into a structured workout using Claude API.
    ///
    /// - Parameter text: Raw text from Vision OCR.
    /// - Returns: A structured ``ExtractedWorkout`` with parsed sections and exercises.
    /// - Throws: Network errors, API errors, or JSON decoding errors.
    public func parseWorkoutText(_ text: String) async throws -> ExtractedWorkout {
        // TODO: Implement HTTP call to Claude API
        // 1. Build URLRequest to https://api.anthropic.com/v1/messages
        // 2. Include API key from environment
        // 3. Send OCR text with ClaudePrompt.workoutParsingPrompt
        // 4. Parse JSON response to ExtractedWorkout
        // 5. Handle errors (network, API, decoding)

        fatalError("ClaudeAPIStrategy not implemented yet - will be filled in next subtask")
    }
}
