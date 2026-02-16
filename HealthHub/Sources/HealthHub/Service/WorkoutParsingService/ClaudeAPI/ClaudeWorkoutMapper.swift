//
//  ClaudeWorkoutMapper.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 15/02/2026.
//

import Foundation
import SharedModels

/// Maps Claude API response to ExtractedWorkout.
///
/// Extracts JSON from Claude response and decodes it directly to ExtractedWorkout.
public struct ClaudeWorkoutMapper {

    // MARK: - Initialization

    public init() {}

    // MARK: - Public Methods

    /// Maps Claude API response to ExtractedWorkout.
    public func map(_ response: ClaudeAPIResponse) throws -> ExtractedWorkout {
        // Extract JSON from content (remove markdown code fence if present)
        guard let contentText = response.content.first?.text else {
            throw ClaudeAPIError.emptyResponse
        }

        let jsonString = try extractJSON(from: contentText)

        guard let jsonData = jsonString.data(using: .utf8) else {
            throw ClaudeAPIError.invalidJSON
        }

        // Decode Claude JSON directly to ExtractedWorkout
        return try JSONDecoder().decode(ExtractedWorkout.self, from: jsonData)
    }

    // MARK: - Private Methods

    /// Extracts JSON from markdown code fence (```json...```).
    private func extractJSON(from text: String) throws -> String {
        var jsonString = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if jsonString.hasPrefix("```json") {
            jsonString = jsonString
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        } else if jsonString.hasPrefix("```") {
            jsonString = jsonString
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return jsonString
    }
}
