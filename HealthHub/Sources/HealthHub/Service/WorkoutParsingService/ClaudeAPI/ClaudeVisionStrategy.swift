//
//  ClaudeVisionStrategy.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 29/10/2026.
//

import Foundation
import SharedModels

/// Claude reads the board photo itself; the OCR transcript is at most a hint.
///
/// Shares the system prompt, output schema and mapper with ``ClaudeStrategy``,
/// so a text-only scan (no photo in the input) falls back to that path unchanged.
public actor ClaudeVisionStrategy: WorkoutParsingStrategy {

    // MARK: - Constants

    private static let scanModel = "claude-sonnet-5-5"

    private static let scanOptions = ClaudeRequestOptions(
        cachesSystemPrompt: true,
        disablesThinking: true,
        effort: .low,
        outputSchema: ClaudeWorkoutOutputSchema.schema
    )

    // MARK: - Properties

    private let apiClient: ClaudeAPIClient
    private let mapper: ClaudeWorkoutMapper
    private let includesOCRHint: Bool
    private let textFallback: ClaudeStrategy

    // MARK: - Initialization

    /// - Parameter includesOCRHint: Sends the OCR transcript next to the photo. Off = control arm
    ///   for measuring whether the hint helps or anchors the model on OCR mistakes.
    public init(
        apiClient: ClaudeAPIClient,
        mapper: ClaudeWorkoutMapper = ClaudeWorkoutMapper(),
        includesOCRHint: Bool
    ) {
        self.apiClient = apiClient
        self.mapper = mapper
        self.includesOCRHint = includesOCRHint
        self.textFallback = ClaudeStrategy(apiClient: apiClient, mapper: mapper)
    }

    public init(apiKey: String? = nil, includesOCRHint: Bool) {
        self.init(apiClient: ClaudeAPIClient.standard(apiKey: apiKey), includesOCRHint: includesOCRHint)
    }

    // MARK: - WorkoutParsingStrategy

    public func parseWorkout(_ input: WorkoutScanInput) async throws -> ExtractedWorkout {
        guard let imageData = input.imageData else {
            return try await parseWorkoutText(input.ocrText)
        }
        let jpeg = try ScanImageDownscaler.jpeg(from: imageData)
        let hint = includesOCRHint ? input.ocrText : nil
        let response = try await apiClient.sendMessage(
            model: Self.scanModel,
            system: ClaudePrompt.systemPrompt,
            content: [
                .image(jpeg, mediaType: "image/jpeg"),
                .text(ClaudePrompt.visionUserPrompt(ocrHint: hint)),
            ],
            options: Self.scanOptions
        )
        return try mapper.map(response)
    }

    public func parseWorkoutText(_ text: String) async throws -> ExtractedWorkout {
        try await textFallback.parseWorkoutText(text)
    }
}
