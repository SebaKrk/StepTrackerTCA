//
//  TrainingNotesGeneratorClient.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 28/02/2026.
//

import ComposableArchitecture
import Foundation
import HealthHub
import SharedModels

// MARK: - Context

struct TrainingNotesContext: Sendable {
    let workouts: [WorkoutSessionNew]
    let durationMinutes: Int?
}

// MARK: - Client

struct TrainingNotesGeneratorClient: Sendable {
    var generateWarmUp: @Sendable (_ context: TrainingNotesContext) async throws -> String
    var generateCoolDown: @Sendable (_ context: TrainingNotesContext) async throws -> String
}

// MARK: - DependencyKey

extension TrainingNotesGeneratorClient: DependencyKey {

    private static let model = "claude-sonnet-4-5-20250929"

    nonisolated static let liveValue: TrainingNotesGeneratorClient = {
        TrainingNotesGeneratorClient(
            generateWarmUp: { context in
                @Dependency(\.apiKeyClient) var apiKeyClient
                let apiClient = ClaudeAPIClient(
                    httpClient: URLSessionHTTPClient(),
                    apiKey: apiKeyClient.load() ?? ""
                )
                let response = try await apiClient.sendMessage(
                    model: TrainingNotesGeneratorClient.model,
                    system: "You are a fitness coach. Generate a concise warm-up description (2-4 sentences) for the given workout. Respond with plain text only, no markdown.",
                    userMessage: warmUpPrompt(for: context)
                )
                return response.content.first?.text ?? ""
            },
            generateCoolDown: { context in
                @Dependency(\.apiKeyClient) var apiKeyClient
                let apiClient = ClaudeAPIClient(
                    httpClient: URLSessionHTTPClient(),
                    apiKey: apiKeyClient.load() ?? ""
                )
                let response = try await apiClient.sendMessage(
                    model: TrainingNotesGeneratorClient.model,
                    system: "You are a fitness coach. Generate a concise cool-down description (2-4 sentences) for the given workout. Respond with plain text only, no markdown.",
                    userMessage: coolDownPrompt(for: context)
                )
                return response.content.first?.text ?? ""
            }
        )
    }()

    static var testValue: TrainingNotesGeneratorClient {
        TrainingNotesGeneratorClient(
            generateWarmUp: unimplemented("TrainingNotesGeneratorClient.generateWarmUp"),
            generateCoolDown: unimplemented("TrainingNotesGeneratorClient.generateCoolDown")
        )
    }
}

// MARK: - DependencyValues

extension DependencyValues {
    var trainingNotesGeneratorClient: TrainingNotesGeneratorClient {
        get { self[TrainingNotesGeneratorClient.self] }
        set { self[TrainingNotesGeneratorClient.self] = newValue }
    }
}

// MARK: - Prompt Helpers

private func warmUpPrompt(for context: TrainingNotesContext) -> String {
    var lines = ["Workout:"]
    for workout in context.workouts {
        lines.append("- \(workout.name) (\(workout.type))")
        for exercise in workout.exercises {
            lines.append("  • \(exercise.displayName)")
        }
    }
    if let duration = context.durationMinutes {
        lines.append("Warm-up duration: \(duration) min")
    }
    lines.append("\nGenerate a warm-up routine for this workout.")
    return lines.joined(separator: "\n")
}

private func coolDownPrompt(for context: TrainingNotesContext) -> String {
    var lines = ["Workout:"]
    for workout in context.workouts {
        lines.append("- \(workout.name) (\(workout.type))")
        for exercise in workout.exercises {
            lines.append("  • \(exercise.displayName)")
        }
    }
    if let duration = context.durationMinutes {
        lines.append("Cool-down duration: \(duration) min")
    }
    lines.append("\nGenerate a cool-down routine for this workout.")
    return lines.joined(separator: "\n")
}
