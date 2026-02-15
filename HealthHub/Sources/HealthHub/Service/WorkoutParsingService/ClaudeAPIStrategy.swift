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

    // MARK: - Constants

    private static let defaultModel = "claude-sonnet-4-5-20250929"

    // MARK: - Properties

    private let apiClient: ClaudeAPIClient
    private let mapper: ClaudeWorkoutMapper

    // MARK: - Initialization

    public init(
        apiClient: ClaudeAPIClient,
        mapper: ClaudeWorkoutMapper = ClaudeWorkoutMapper()
    ) {
        self.apiClient = apiClient
        self.mapper = mapper
    }

    /// Convenience initializer with default HTTPClient.
    public init(apiKey: String? = nil) {
        let httpClient = URLSessionHTTPClient()
        let apiClient = ClaudeAPIClient(httpClient: httpClient, apiKey: apiKey)
        self.init(apiClient: apiClient)
    }

    // MARK: - WorkoutParsingStrategy

    /// Parses OCR text into a structured workout using Claude API.
    ///
    /// - Parameter text: Raw text from Vision OCR.
    /// - Returns: A structured ``ExtractedWorkout`` with parsed sections and exercises.
    /// - Throws: ``ClaudeAPIError`` or HTTP/JSON errors.
    public func parseWorkoutText(_ text: String) async throws -> ExtractedWorkout {
        let response = try await apiClient.sendMessage(
            model: Self.defaultModel,
            system: ClaudePrompt.systemPrompt,
            userMessage: ClaudePrompt.userPrompt(ocrText: text)
        )

        return try mapper.map(response, rawText: text)
    }
}
