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

    private let apiKey: String
    private let session: URLSession

    public init(
        apiKey: String? = nil,
        session: URLSession = .shared
    ) {
        // API key from parameter or environment variable
        self.apiKey = apiKey ?? ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] ?? ""
        self.session = session
    }

    /// Parses OCR text into a structured workout using Claude API.
    ///
    /// - Parameter text: Raw text from Vision OCR.
    /// - Parameter text: Raw text from Vision OCR.
    /// - Returns: A structured ``ExtractedWorkout`` with parsed sections and exercises.
    /// - Throws: ``ClaudeAPIError`` or JSON decoding errors.
    public func parseWorkoutText(_ text: String) async throws -> ExtractedWorkout {
        let rawText = text  // Save for later
        guard !apiKey.isEmpty else {
            throw ClaudeAPIError.missingAPIKey
        }

        // Build request
        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        // Request body
        let requestBody = ClaudeAPIRequest(
            model: "claude-sonnet-4-5-20250929",
            maxTokens: 4096,
            system: ClaudePrompt.systemPrompt,
            messages: [
                .init(role: "user", content: ClaudePrompt.userPrompt(ocrText: text))
            ]
        )

        request.httpBody = try JSONEncoder().encode(requestBody)

        // Send request
        let (data, response) = try await session.data(for: request)

        // Check HTTP status
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudeAPIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw ClaudeAPIError.httpError(statusCode: httpResponse.statusCode)
        }

        // Parse response
        let apiResponse = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)

        // Extract JSON from content
        guard let contentText = apiResponse.content.first?.text else {
            throw ClaudeAPIError.emptyResponse
        }

        // Remove markdown code fence if present (Claude 4.5 wraps JSON in ```json...```)
        var jsonString = contentText.trimmingCharacters(in: .whitespacesAndNewlines)
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

        // Parse JSON to intermediate type (without rawText)
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw ClaudeAPIError.invalidJSON
        }

        let workoutResponse = try JSONDecoder().decode(ClaudeWorkoutResponse.self, from: jsonData)

        // Convert to ExtractedWorkout (add rawText)
        let sections = workoutResponse.sections.map { section in
            convertSection(section)
        }

        return ExtractedWorkout(
            name: workoutResponse.name,
            date: workoutResponse.date,
            totalEstimatedMinutes: workoutResponse.totalEstimatedMinutes,
            rawText: rawText,
            sections: sections
        )
    }

    // MARK: - Conversion Helpers

    private func convertSection(_ section: ClaudeWorkoutSection) -> WorkoutSection {
        let exercises = section.exercises?.map { convertExercise($0) }

        return WorkoutSection(
            type: SectionType(rawValue: section.type) ?? .warmup,
            name: section.name,
            durationMinutes: section.durationMinutes,
            description: section.description,
            timeCapMinutes: section.timeCapMinutes,
            rounds: section.rounds,
            exercises: exercises,
            notes: section.notes
        )
    }

    private func convertExercise(_ exercise: ClaudeExercise) -> ExtractedExercise {
        let sets = exercise.sets?.map { convertSet($0) }

        return ExtractedExercise(
            name: exercise.name,
            reps: exercise.reps,
            sets: sets,
            scalingOptions: exercise.scalingOptions
        )
    }

    private func convertSet(_ set: ClaudeExerciseSet) -> ExerciseSet {
        ExerciseSet(
            setNumber: set.setNumber,
            reps: set.reps,
            intensity: set.intensity,
            restSeconds: set.restSeconds
        )
    }
}

// MARK: - Request/Response Models

private struct ClaudeAPIRequest: Encodable {
    let model: String
    let maxTokens: Int
    let system: String
    let messages: [Message]

    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case system
        case messages
    }

    struct Message: Encodable {
        let role: String
        let content: String
    }
}

private struct ClaudeAPIResponse: Decodable {
    let content: [Content]

    struct Content: Decodable {
        let text: String
    }
}

// MARK: - Claude Workout Response (matches Claude JSON output)

private struct ClaudeWorkoutResponse: Decodable {
    let name: String
    let date: String
    let totalEstimatedMinutes: Int
    let sections: [ClaudeWorkoutSection]
}

private struct ClaudeWorkoutSection: Decodable {
    let type: String
    let name: String?
    let durationMinutes: Int?
    let description: String?
    let timeCapMinutes: Int?
    let rounds: String?
    let exercises: [ClaudeExercise]?
    let notes: String?
}

private struct ClaudeExercise: Decodable {
    let name: String
    let reps: Int?
    let sets: [ClaudeExerciseSet]?
    let scalingOptions: String?
}

private struct ClaudeExerciseSet: Decodable {
    let setNumber: Int
    let reps: Int
    let intensity: String?
    let restSeconds: Int?
}

// MARK: - Errors

public enum ClaudeAPIError: Error, LocalizedError {
    case missingAPIKey
    case invalidResponse
    case httpError(statusCode: Int)
    case emptyResponse
    case invalidJSON

    public var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Claude API key not found. Set ANTHROPIC_API_KEY environment variable."
        case .invalidResponse:
            return "Invalid response from Claude API"
        case .httpError(let statusCode):
            return "Claude API HTTP error: \(statusCode)"
        case .emptyResponse:
            return "Claude API returned empty response"
        case .invalidJSON:
            return "Failed to parse workout JSON from Claude response"
        }
    }
}
