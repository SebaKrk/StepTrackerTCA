//
//  InlineResultEditor+CounterPreviews.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/11/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

// MARK: - Previews

/// One movement that states its own share of the round.
private func movement(_ type: ExerciseType, _ target: ExerciseTarget, weight: Double? = nil) -> ExerciseLogInput {
    ExerciseLogInput(exerciseType: type, target: target, plannedReps: target.compactString, plannedWeight: weight)
}

/// A card as it stands after the athlete set both counters, so the rows show what the score implies.
private func counted(
    _ state: WODScoringFeature.State,
    unfinished: Bool,
    first: Int,
    second: Int
) -> StoreOf<WODScoringFeature> {
    var card = state
    card.phase = .editing
    let store = Store(initialState: card) { WODScoringFeature() }
    if unfinished { store.send(.view(.setStatus(.notFinished))) }
    store.send(.view(.updateRounds(first)))
    store.send(.view(.updateExtraReps(second)))
    return store
}

private func counterCase(_ board: String, _ store: StoreOf<WODScoringFeature>) -> some View {
    VStack(alignment: .leading, spacing: 8) {
        Text(verbatim: board)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white.opacity(0.6))
        VStack {
            InlineResultEditor(store: store, accent: SummaryTheme.mint)
        }
        .summaryCard()
    }
}

#Preview("Liczniki 1–3 · AMRAP / For Time bez rund / For Time 3 rundy") {
    ScrollView {
        VStack(spacing: 24) {
            counterCase(
                "1 · AMRAP 12': 10 pull-ups, 15 push-ups, 20 air squats — 5 rund + 17",
                counted(
                    WODScoringFeature.State(
                        wodIndex: 0,
                        result: WorkoutSessionResult(
                            name: "WOD 1",
                            description: "AMRAP 12'",
                            exercises: [
                                movement(.pullUps, .reps(10)),
                                movement(.pushUps, .reps(15)),
                                movement(.airSquat, .reps(20)),
                            ]
                        ),
                        wodType: .amrap,
                        capMinutes: 12
                    ),
                    unfinished: false,
                    first: 5,
                    second: 17
                )
            )

            counterCase(
                "2 · For Time, cap 11': 50 KB swings, 75 burpees, 50 box step-ups — stop na 6 step-upach",
                counted(
                    WODScoringFeature.State(
                        wodIndex: 1,
                        result: WorkoutSessionResult(
                            name: "WOD 1",
                            description: "For Time",
                            exercises: [
                                movement(.kettlebellSwing, .reps(50), weight: 24),
                                movement(.burpees, .reps(75)),
                                movement(.boxStepUps, .reps(50)),
                            ]
                        ),
                        wodType: .forTime,
                        capMinutes: 11
                    ),
                    unfinished: true,
                    first: 2,
                    second: 6
                )
            )

            counterCase(
                "3 · 3 rundy na czas, cap 15': 20 wall balls, 15 toes to bar, 10 burpees — 2 rundy + 28",
                counted(
                    WODScoringFeature.State(
                        wodIndex: 2,
                        result: WorkoutSessionResult(
                            name: "WOD 1",
                            description: "3 Rounds For Time",
                            exercises: [
                                movement(.wallBalls, .reps(20), weight: 9),
                                movement(.toesToBar, .reps(15)),
                                movement(.burpees, .reps(10)),
                            ]
                        ),
                        wodType: .forTime,
                        capMinutes: 15,
                        rounds: 3
                    ),
                    unfinished: true,
                    first: 2,
                    second: 28
                )
            )
        }
        .padding(16)
    }
    .background(SummaryTheme.background)
}

#Preview("Liczniki 4–6 · drabinka 21-15-9 / otwarta drabinka / bieg ze stacjami") {
    ScrollView {
        VStack(spacing: 24) {
            counterCase(
                "4 · 21-15-9 na czas, cap 8': thrusters, pull-ups — runda 21 cała + 19 w rundzie 15",
                counted(
                    WODScoringFeature.State(
                        wodIndex: 0,
                        result: WorkoutSessionResult(
                            name: "WOD 1",
                            description: "For Time: 21-15-9",
                            exercises: [
                                ExerciseLogInput(exerciseType: .thrusters, plannedReps: "45", plannedWeight: 43),
                                ExerciseLogInput(exerciseType: .pullUps, plannedReps: "45"),
                            ]
                        ),
                        wodType: .forTime,
                        capMinutes: 8,
                        repScheme: [21, 15, 9]
                    ),
                    unfinished: true,
                    first: 1,
                    second: 19
                )
            )

            counterCase(
                "5 · AMRAP 10', drabinka 3-6-9-12…: deadlift, box jumps — 4 rundy + 8 w rundzie 5",
                counted(
                    WODScoringFeature.State(
                        wodIndex: 1,
                        result: WorkoutSessionResult(
                            name: "WOD 1",
                            description: "AMRAP 10'",
                            exercises: [
                                ExerciseLogInput(exerciseType: .deadlift, plannedWeight: 80),
                                ExerciseLogInput(exerciseType: .boxJumps),
                            ]
                        ),
                        wodType: .amrap,
                        capMinutes: 10,
                        openLadder: OpenLadderPlan(firstRung: 3, step: 3)
                    ),
                    unfinished: false,
                    first: 4,
                    second: 8
                )
            )

            counterCase(
                "6 · Bieg ze stacjami: 3 × 1000 m + ski erg, sled push, wall balls — 1 stacja cała",
                counted(
                    WODScoringFeature.State(
                        wodIndex: 2,
                        result: WorkoutSessionResult(
                            name: "WOD 1",
                            description: "Fitness run",
                            exercises: [
                                movement(.running, .meters(3000)),
                                movement(.skiErg, .meters(1000)),
                                movement(.sledPush, .meters(50), weight: 152),
                                movement(.wallBalls, .reps(100), weight: 6),
                            ]
                        ),
                        wodType: .forTime,
                        fitnessRun: FitnessRunPlan(runMeters: 1000)
                    ),
                    unfinished: true,
                    first: 1,
                    second: 0
                )
            )
        }
        .padding(16)
    }
    .background(SummaryTheme.background)
}
