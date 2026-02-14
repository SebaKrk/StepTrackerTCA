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
    /// - Returns: A structured ``ExtractedWorkout`` with parsed sections and exercises.
    /// - Throws: ``ClaudeAPIError`` or JSON decoding errors.
    public func parseWorkoutText(_ text: String) async throws -> ExtractedWorkout {
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
            model: "claude-3-5-sonnet-20241022",
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

        // Parse ExtractedWorkout from JSON
        guard let jsonData = contentText.data(using: .utf8) else {
            throw ClaudeAPIError.invalidJSON
        }

        let workout = try JSONDecoder().decode(ExtractedWorkout.self, from: jsonData)
        return workout
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
