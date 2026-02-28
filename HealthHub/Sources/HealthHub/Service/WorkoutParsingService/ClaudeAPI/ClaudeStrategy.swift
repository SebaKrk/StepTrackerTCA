//
//  ClaudeStrategy.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 28/02/2026.
//

import Foundation
import SharedModels

/// Unified Claude API strategy for all AI-powered features.
///
/// Handles two categories of requests:
/// - **Structured parsing** — OCR text → ``ExtractedWorkout`` (JSON response)
/// - **Text generation** — workout data → plain-text descriptions (warm-up, cool-down)
///
/// The response language for text generation is automatically matched to the device locale.
public actor ClaudeStrategy: WorkoutParsingStrategy {

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
        let apiClient = ClaudeAPIClient(httpClient: URLSessionHTTPClient(), apiKey: apiKey)
        self.init(apiClient: apiClient)
    }

    // MARK: - WorkoutParsingStrategy

    /// Parses OCR text into a structured workout using Claude API.
    public func parseWorkoutText(_ text: String) async throws -> ExtractedWorkout {
        let response = try await apiClient.sendMessage(
            model: Self.defaultModel,
            system: ClaudePrompt.systemPrompt,
            userMessage: ClaudePrompt.userPrompt(ocrText: text)
        )
        return try mapper.map(response)
    }

    // MARK: - Text Generation

    /// Generates a warm-up description for the given workouts.
    public func generateWarmUp(
        workouts: [WorkoutSessionNew],
        durationMinutes: Int?
    ) async throws -> String {
        try await generateText(
            system: TrainingNotesPrompt.warmUpSystem,
            userMessage: TrainingNotesPrompt.warmUpUser(workouts: workouts, durationMinutes: durationMinutes)
        )
    }

    /// Generates a cool-down description for the given workouts.
    public func generateCoolDown(
        workouts: [WorkoutSessionNew],
        durationMinutes: Int?
    ) async throws -> String {
        try await generateText(
            system: TrainingNotesPrompt.coolDownSystem,
            userMessage: TrainingNotesPrompt.coolDownUser(workouts: workouts, durationMinutes: durationMinutes)
        )
    }

    // MARK: - Private

    private func generateText(system: String, userMessage: String) async throws -> String {
        let localizedSystem = "\(system) Respond in \(preferredLanguageName())."
        let response = try await apiClient.sendMessage(
            model: Self.defaultModel,
            system: localizedSystem,
            userMessage: userMessage
        )
        return response.content.first?.text ?? ""
    }

    private func preferredLanguageName() -> String {
        let code = Locale.current.language.languageCode?.identifier ?? "en"
        return Locale(identifier: "en").localizedString(forLanguageCode: code) ?? "English"
    }
}
