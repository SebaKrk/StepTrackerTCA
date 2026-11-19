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
    var generateMissing: @Sendable (_ context: TrainingNotesContext, _ warmUp: Bool, _ coolDown: Bool) async throws -> TrainingNotes
}

// MARK: - DependencyKey

extension TrainingNotesGeneratorClient: DependencyKey {

    /// Production client; the cue is written by the proxy, which holds the API key.
    nonisolated static let liveValue: TrainingNotesGeneratorClient = {
        TrainingNotesGeneratorClient(
            generateWarmUp: { context in
                try await note(.warmUp, context)
            },
            generateCoolDown: { context in
                try await note(.coolDown, context)
            },
            generateMissing: { context, warmUp, coolDown in
                try await ScanProxy.shared.proposedNotes(
                    warmUp: warmUp,
                    coolDown: coolDown,
                    workouts: context.workouts.map(noteWorkout),
                    language: ScanLanguage.preferredName()
                )
            }
        )
    }()

    /// One proxy round-trip for either cue.
    nonisolated private static func note(_ kind: TrainingNoteKind, _ context: TrainingNotesContext) async throws -> String {
        try await ScanProxy.shared.trainingNote(
            kind: kind,
            workouts: context.workouts.map(noteWorkout),
            durationMinutes: context.durationMinutes,
            language: ScanLanguage.preferredName()
        )
    }

    /// Names only — the proxy owns the wording of the prompt.
    nonisolated private static func noteWorkout(_ workout: WorkoutSessionNew) -> TrainingNoteWorkout {
        TrainingNoteWorkout(
            name: workout.name,
            type: workout.type.rawValue,
            exercises: workout.exercises.map(\.displayName)
        )
    }

    static var testValue: TrainingNotesGeneratorClient {
        TrainingNotesGeneratorClient(
            generateWarmUp: unimplemented("TrainingNotesGeneratorClient.generateWarmUp"),
            generateCoolDown: unimplemented("TrainingNotesGeneratorClient.generateCoolDown"),
            generateMissing: unimplemented("TrainingNotesGeneratorClient.generateMissing")
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
