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

    nonisolated static let liveValue: TrainingNotesGeneratorClient = {
        TrainingNotesGeneratorClient(
            generateWarmUp: { context in
                @Dependency(\.apiKeyClient) var apiKeyClient
                let strategy = ClaudeStrategy(apiKey: apiKeyClient.load())
                return try await strategy.generateWarmUp(
                    workouts: context.workouts,
                    durationMinutes: context.durationMinutes
                )
            },
            generateCoolDown: { context in
                @Dependency(\.apiKeyClient) var apiKeyClient
                let strategy = ClaudeStrategy(apiKey: apiKeyClient.load())
                return try await strategy.generateCoolDown(
                    workouts: context.workouts,
                    durationMinutes: context.durationMinutes
                )
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
