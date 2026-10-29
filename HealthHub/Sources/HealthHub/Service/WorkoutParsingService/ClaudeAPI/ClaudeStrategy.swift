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
/// - **Structured parsing** — OCR text → ``ScannedBoard`` (structured-output JSON)
/// - **Text generation** — workout data → plain-text descriptions (warm-up, cool-down)
///
/// The response language for text generation is automatically matched to the device locale.
public actor ClaudeStrategy: WorkoutParsingStrategy {

    // MARK: - Constants

    private static let scanModel = "claude-sonnet-5-5"
    private static let notesModel = "claude-sonnet-5-5"

    /// Structured JSON, cached rules, no thinking: the board is read, not reasoned about.
    private static let scanOptions = ClaudeRequestOptions(
        cachesSystemPrompt: true,
        disablesThinking: true,
        effort: .low,
        outputSchema: ClaudeBoardOutputSchema.schema
    )

    /// Short prompts below the cacheable minimum; plain text out.
    private static let notesOptions = ClaudeRequestOptions(
        disablesThinking: true,
        effort: .medium
    )

    // MARK: - Properties

    /// Transport to the Messages API.
    private let apiClient: ClaudeAPIClient

    /// Turns the JSON reply into the board DTO.
    private let mapper: ClaudeBoardMapper

    // MARK: - Initialization

    public init(
        apiClient: ClaudeAPIClient,
        mapper: ClaudeBoardMapper = ClaudeBoardMapper()
    ) {
        self.apiClient = apiClient
        self.mapper = mapper
    }

    /// Convenience initializer with default HTTPClient.
    public init(apiKey: String? = nil) {
        self.init(apiClient: ClaudeAPIClient.standard(apiKey: apiKey))
    }

    // MARK: - WorkoutParsingStrategy

    /// Parses OCR text into a scanned board using Claude API.
    public func parseWorkoutText(_ text: String) async throws -> ScannedBoard {
        let response = try await apiClient.sendMessage(
            model: Self.scanModel,
            system: ClaudePrompt.systemPrompt,
            userMessage: ClaudePrompt.userPrompt(ocrText: text),
            options: Self.scanOptions
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
            model: Self.notesModel,
            system: localizedSystem,
            userMessage: userMessage,
            options: Self.notesOptions
        )
        return response.firstText ?? ""
    }

    private func preferredLanguageName() -> String {
        let code = Locale.current.language.languageCode?.identifier ?? "en"
        return Locale(identifier: "en").localizedString(forLanguageCode: code) ?? "English"
    }
}
