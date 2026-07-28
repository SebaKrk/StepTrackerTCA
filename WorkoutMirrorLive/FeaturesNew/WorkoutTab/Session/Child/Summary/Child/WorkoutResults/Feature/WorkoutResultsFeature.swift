//
//  WorkoutResultsFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 27/07/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

/// Portable "Wyniki" section — a container of per-WOD scoring cards.
/// Embedded editable in the Summary screen and read-only in ActivityDetails,
/// so both render workout results identically.
@Reducer
struct WorkoutResultsFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {

        var cards: IdentifiedArrayOf<WODScoringFeature.State> = []

        /// Typed results for the save flow.
        var results: [WorkoutSessionResult] { cards.map(\.result) }
    }

    // MARK: - Action

    @CasePathable
    enum Action {
        case cards(IdentifiedActionOf<WODScoringFeature>)
    }

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        EmptyReducer()
            .forEach(\.cards, action: \.cards) {
                WODScoringFeature()
            }
    }
}

// MARK: - Factories

extension WorkoutResultsFeature.State {

    /// Editable cards for the Summary screen. `existingResults` (edit flow from
    /// History) reuses saved results; otherwise fresh results are built from the plan.
    static func editable(
        trainingSession: TrainingSession,
        existingResults: [WorkoutSessionResult]? = nil
    ) -> Self {
        let workouts = trainingSession.workouts
        let results = existingResults ?? freshResults(from: workouts)
        var state = Self()
        state.cards = IdentifiedArrayOf(
            uniqueElements: results.enumerated().map { index, result in
                let workout = workouts.indices.contains(index) ? workouts[index] : nil
                return WODScoringFeature.State(
                    wodIndex: index,
                    result: result,
                    wodType: workout?.type,
                    capMinutes: workout?.timeCap
                )
            }
        )
        return state
    }

    /// Read-only cards for ActivityDetails (type/cap derived from the saved result).
    static func readOnly(results: [WorkoutSessionResult]) -> Self {
        var state = Self()
        state.cards = IdentifiedArrayOf(
            uniqueElements: results.enumerated().map { index, result in
                WODScoringFeature.State(wodIndex: index, result: result, isReadOnly: true)
            }
        )
        return state
    }

    /// Fresh, empty results mapped from the plan (moved from SummaryFeature.setTrainingSession).
    private static func freshResults(from workouts: [WorkoutSessionNew]) -> [WorkoutSessionResult] {
        let isStrength = { (type: ExerciseWorkoutType) -> Bool in
            type == .strength || type == .olympicWeightlifting
        }
        return workouts.map { workout -> WorkoutSessionResult in
            let exercises = workout.exercises.map { exercise in
                // For Strength/Olympic WODs → use AI-provided structured plannedSets,
                // fallback to rounds-based default sets if AI didn't deliver them.
                let sets: [SetEntry]? = {
                    guard isStrength(workout.type) else { return nil }

                    if let planned = exercise.plannedSets, !planned.isEmpty {
                        return planned.map {
                            SetEntry(reps: $0.reps, weight: $0.suggestedWeight)
                        }
                    }

                    guard let rounds = workout.rounds else { return nil }
                    let reps: Int
                    if case let .reps(r) = exercise.target { reps = r } else { reps = 0 }
                    return (0..<rounds).map { _ in SetEntry(reps: reps) }
                }()

                let weight = exercise.weight.flatMap { config in
                    config.men.map(Double.init) ?? config.women.map(Double.init)
                }

                return ExerciseLogInput(
                    exerciseType: exercise.type,
                    unmatchedName: exercise.customName,
                    category: exercise.type.category,
                    target: exercise.target,
                    plannedReps: exercise.target?.compactString,
                    plannedWeight: weight,
                    actualWeight: sets == nil ? weight : nil,
                    actualReps: sets == nil ? exercise.target?.compactString : nil,
                    sets: sets
                )
            }
            return WorkoutSessionResult(
                name: workout.name,
                description: workout.snapshotDescription,
                exercises: exercises
            )
        }
    }
}
