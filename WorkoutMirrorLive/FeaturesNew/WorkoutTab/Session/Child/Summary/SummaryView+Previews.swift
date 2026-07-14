//
//  SummaryView+Previews.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 27/06/2026.
//

import ComposableArchitecture
import HealthKit
import SharedModels
import SwiftUI

#Preview("failed") {
    let state: SummaryFeature.State = {
        var state = SummaryFeature.State(viewState: .failed)
        state.summaryRetryCount = 20
        state.failureDebugInfo = "mode: watchPrimary, workout: nil, attempts: 20, metrics: WorkoutMetrics(avg: 145, hr: 0, energy: 520)"
        return state
    }()
    SummaryView(store: Store(initialState: state) {
        SummaryFeature()
    } withDependencies: {
        $0.sessionClient.getWorkoutSummary = {
            await withCheckedContinuation { (_: CheckedContinuation<WorkoutSummary, Never>) in }
        }
    })
}

#Preview("saving") {
    SummaryView(store: Store(initialState: SummaryFeature.State(), reducer: {
        SummaryFeature()
    }))
}

#Preview("loading") {
    SummaryView(store: Store(initialState: SummaryFeature.State(viewState: .loading), reducer: {
        SummaryFeature()
    }, withDependencies: {
        // Never resolves → the view stays on the loading spinner, so this preview
        // shows exactly the loading state (checkSummary keeps waiting).
        $0.sessionClient.getWorkoutSummary = {
            await withCheckedContinuation { (_: CheckedContinuation<WorkoutSummary, Never>) in }
        }
    }))
}

#Preview("loaded — short") {
    let summary = WorkoutSummary.previewWorkoutSummary()
    let state: SummaryFeature.State = {
        var state = SummaryFeature.State(viewState: .successfullyLoaded)
        state.summary = summary
        state.effortPoints = 190          // shows the effort points card in the metrics grid
        state.dominantZone = .threshold   // tints the background gradient (Zone 4)
        return state
    }()
    NavigationStack {
        SummaryView(store: Store(initialState: state) {
            SummaryFeature()
        } withDependencies: {
            $0.sessionClient.getWorkoutSummary = { summary }
        })
    }
}

#Preview("loaded — long (2h+)") {
    let summary: WorkoutSummary = {
        let end = Date()
        let start = end.addingTimeInterval(-7890) // 2h 11m 30s
        let workout = HKWorkout(activityType: .crossTraining, start: start, end: end)
        return WorkoutSummary(
            workout: workout,
            metrics: WorkoutMetrics(averageHeartRate: 155, heartRate: 178, activeEnergy: 1240)
        )
    }()
    let state: SummaryFeature.State = {
        var state = SummaryFeature.State(viewState: .successfullyLoaded)
        state.summary = summary
        return state
    }()
    NavigationStack {
        SummaryView(store: Store(initialState: state) {
            SummaryFeature()
        } withDependencies: {
            $0.sessionClient.getWorkoutSummary = { summary }
        })
    }
}

#Preview("Monday — AMRAP + Strength") {
    let state: SummaryFeature.State = {
        let workout = HKWorkout(activityType: .crossTraining, start: Date().addingTimeInterval(-3600), end: Date())
        let summary = WorkoutSummary(workout: workout, metrics: WorkoutMetrics(averageHeartRate: 155, heartRate: 172, activeEnergy: 580))
        var state = SummaryFeature.State(viewState: .successfullyLoaded)
        state.summary = summary
        let inputs: [WorkoutSessionResult] = [
            WorkoutSessionResult(
                name: "WOD",
                description: "AMRAP 25': 3 Ring Muscle-ups or 9 Pull-ups, 8 Thrusters @50/35kg, 17 Cal Row",
                scoreResult: .amrap(rounds: 6, extraReps: 14),
                exercises: [
                    ExerciseLogInput(
                        exerciseType: .pullUps,
                        category: .gymnastics,
                        target: .reps(9),
                        plannedReps: "9",
                        actualReps: "9"
                    ),
                    ExerciseLogInput(
                        exerciseType: .thrusters,
                        category: .olympicLifting,
                        target: .reps(8),
                        plannedReps: "8",
                        plannedWeight: 50,
                        actualWeight: 50,
                        actualReps: "8"
                    ),
                    ExerciseLogInput(
                        exerciseType: .rowing,
                        category: .cardio,
                        target: .calories(17),
                        plannedReps: "17 cal",
                        actualReps: "17"
                    ),
                ]
            ),
            WorkoutSessionResult(
                name: "Strength",
                description: "5 sets for load: 10 Close-Grip Bench Press",
                scoreResult: .forLoad(weight: 60),
                exercises: [
                    ExerciseLogInput(
                        exerciseType: .benchPress,
                        category: .strength,
                        target: .reps(10),
                        plannedReps: "10-10-10-10-10",
                        sets: [
                            SetEntry(reps: 10, weight: 40),
                            SetEntry(reps: 10, weight: 45),
                            SetEntry(reps: 10, weight: 50),
                            SetEntry(reps: 10, weight: 55),
                            SetEntry(reps: 10, weight: 60),
                        ]
                    ),
                ]
            ),
        ]
        state.wodScorings = IdentifiedArrayOf(
            uniqueElements: inputs.enumerated().map { index, result in
                WODScoringFeature.State(wodIndex: index, result: result, showResults: true)
            }
        )
        return state
    }()
    NavigationStack {
        SummaryView(store: Store(initialState: state) {
            EmptyReducer()
        })
    }
}

#Preview("CrossFit — FOR TIME") {
    let state: SummaryFeature.State = {
        let workout = HKWorkout(activityType: .crossTraining, start: Date().addingTimeInterval(-2400), end: Date())
        let summary = WorkoutSummary(workout: workout, metrics: WorkoutMetrics(averageHeartRate: 165, heartRate: 178, activeEnergy: 620))
        var state = SummaryFeature.State(viewState: .successfullyLoaded)
        state.summary = summary
        let inputs: [WorkoutSessionResult] = [
            WorkoutSessionResult(
                name: "WOD 1",
                description: "FOR TIME TC 15': 21-15-9 Thrusters 43/30kg + Burpees + T2B",
                scoreResult: .forTime(time: 872),
                exercises: [
                    ExerciseLogInput(exerciseType: .thrusters, category: .olympicLifting, plannedReps: "21-15-9", plannedWeight: 43, actualWeight: 43, actualReps: "21-15-9", isPR: true),
                    ExerciseLogInput(exerciseType: .burpees, category: .mixed, plannedReps: "21-15-9", actualReps: "21-15-9"),
                    ExerciseLogInput(exerciseType: .toesToBar, category: .gymnastics, plannedReps: "21-15-9", actualReps: "21-15-9"),
                ]
            ),
            WorkoutSessionResult(
                name: "WOD 2",
                description: "FOR TIME: 50 Wall Balls 9kg + 30 Box Jumps + 20 C&J 60/40kg",
                scoreResult: .timeCap(capSeconds: 900, remainingReps: 12),
                exercises: [
                    ExerciseLogInput(exerciseType: .wallBalls, category: .mixed, plannedReps: "50", plannedWeight: 9, actualWeight: 9, actualReps: "50"),
                    ExerciseLogInput(exerciseType: .boxJumps, category: .mixed, plannedReps: "30", actualReps: "30"),
                    ExerciseLogInput(exerciseType: .cleanAndJerk, category: .olympicLifting, plannedReps: "20", plannedWeight: 60, actualWeight: 60, actualReps: "8", scaling: .rx),
                ]
            ),
        ]
        state.wodScorings = IdentifiedArrayOf(
            uniqueElements: inputs.enumerated().map { index, result in
                WODScoringFeature.State(wodIndex: index, result: result, showResults: true)
            }
        )
        return state
    }()
    NavigationStack {
        SummaryView(store: Store(initialState: state) {
            EmptyReducer()
        })
    }
}

#Preview("CrossFit — AMRAP + EMOM") {
    let state: SummaryFeature.State = {
        let workout = HKWorkout(activityType: .crossTraining, start: Date().addingTimeInterval(-3000), end: Date())
        let summary = WorkoutSummary(workout: workout, metrics: WorkoutMetrics(averageHeartRate: 158, heartRate: 172, activeEnergy: 550))
        var state = SummaryFeature.State(viewState: .successfullyLoaded)
        state.summary = summary
        let inputs: [WorkoutSessionResult] = [
            WorkoutSessionResult(
                name: "EMOM 10'",
                description: "EMOM 10min: 3 Power Clean 70/50kg + 6 Push-ups",
                scoreResult: .completed,
                exercises: [
                    ExerciseLogInput(exerciseType: .powerClean, category: .olympicLifting, plannedReps: "3 per min", plannedWeight: 70, actualWeight: 70, actualReps: "3 per min"),
                    ExerciseLogInput(exerciseType: .pushUps, category: .gymnastics, plannedReps: "6 per min", actualReps: "6 per min"),
                ]
            ),
            WorkoutSessionResult(
                name: "WOD",
                description: "AMRAP 15': 5 HSPU, 10 KB Swing 24/16kg, 15 Cal Row",
                scoreResult: .amrap(rounds: 6, extraReps: 8),
                exercises: [
                    ExerciseLogInput(exerciseType: .handstandPushUps, category: .gymnastics, plannedReps: "5", actualReps: "5"),
                    ExerciseLogInput(exerciseType: .kettlebellSwing, category: .strength, plannedReps: "10", plannedWeight: 24, actualWeight: 24, actualReps: "10"),
                    ExerciseLogInput(exerciseType: .rowing, category: .cardio, plannedReps: "15 cal", actualReps: "15 cal"),
                ]
            ),
        ]
        state.wodScorings = IdentifiedArrayOf(
            uniqueElements: inputs.enumerated().map { index, result in
                WODScoringFeature.State(wodIndex: index, result: result, showResults: true)
            }
        )
        return state
    }()
    NavigationStack {
        SummaryView(store: Store(initialState: state) {
            EmptyReducer()
        })
    }
}
