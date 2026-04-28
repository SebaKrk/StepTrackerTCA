//
//  SummaryFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 30/08/2025.
//

import ComposableArchitecture
import HealthKit
import IssueReporting
import SharedModels
import Foundation

@Reducer
struct SummaryFeature {

    // MARK: - Dependency

    @Dependency(\.sessionClient) var client
    @Dependency(\.workoutPlanScoreClient) var workoutPlanScoreClient
    @Dependency(\.exerciseLogClient) var exerciseLogClient
    @Dependency(\.dismiss) var dismiss

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {

                // MARK: - Action

            case let .changeViewState(viewState):
                state.viewState = viewState
                return .none

            case .checkSummary:
                state.summaryRetryCount += 1
                let attempt = state.summaryRetryCount
                return .run { send in
                    await WorkoutFileLogger.shared.log("SUMMARY CHECK — attempt #\(attempt)")
                    let summary = await client.getWorkoutSummary()
                    await send(.summaryLoaded(summary))
                }

            case let .setTrainingSession(trainingSession):
                state.trainingSession = trainingSession
                let workouts = trainingSession?.workouts ?? []
                let isStrength = { (type: ExerciseWorkoutType) -> Bool in
                    type == .strength || type == .olympicWeightlifting
                }
                state.resultInputs = workouts.map { workout in
                    let exercises = workout.exercises.map { exercise in
                        // For Strength/Olympic WODs with rounds → create per-set entries
                        let sets: [SetEntry]? = {
                            guard isStrength(workout.type), let rounds = workout.rounds else { return nil }
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
                state.showResults = Array(repeating: false, count: workouts.count)
                state.showNotes = Array(repeating: false, count: workouts.count)
                state.exercisesEdited = Array(repeating: false, count: workouts.count)
                return .none

            case .workoutSavedReceived:
                guard state.viewState == .saving else { return .none }
                return .merge(
                    .cancel(id: SummaryFeatureCancelID.savingTimeout),
                    .run { send in
                        await WorkoutFileLogger.shared.log("SUMMARY — .workoutSaved received from Watch, starting poll")
                        await send(.changeViewState(.loading))
                        await send(.checkSummary)
                    }
                )

            case .workoutSavedTimeout:
                guard state.viewState == .saving else { return .none }
                return .run { send in
                    await WorkoutFileLogger.shared.log("SUMMARY — .workoutSaved timeout (10s), falling back to poll")
                    await send(.changeViewState(.loading))
                    await send(.checkSummary)
                }

            case let .setHRData(hrBuffer, phaseTimestamps):
                state.hrBuffer = hrBuffer
                state.phaseTimestamps = phaseTimestamps
                return .none

            case let .summaryLoaded(summary):
                state.summary = summary
                let resultLog = summary.workout.map { "found: \($0.uuid)" } ?? "nil"

                if summary.workout != nil {
                    state.viewState = .successfullyLoaded
                    return .merge(
                        .cancel(id: SummaryFeatureCancelID.retry),
                        .run { _ in await WorkoutFileLogger.shared.log("SUMMARY RESULT — workout: \(resultLog)") }
                    )
                } else if state.summaryRetryCount >= 20 {
                    state.viewState = .failed
                    state.failureDebugInfo += ", workout: \(resultLog), attempts: \(state.summaryRetryCount), metrics: \(summary.metrics)"
                    return .run { [debugInfo = state.failureDebugInfo] _ in
                        await WorkoutFileLogger.shared.log("SUMMARY FAILED — \(debugInfo)")
                    }
                } else {
                    state.viewState = .loading
                    return .merge(
                        .run { _ in await WorkoutFileLogger.shared.log("SUMMARY RESULT — workout: \(resultLog) → will retry in 3s") },
                        .run { send in
                            try? await Task.sleep(for: .milliseconds(3000))
                            await send(.checkSummary)
                        }
                        .cancellable(id: SummaryFeatureCancelID.retry, cancelInFlight: true)
                    )
                }

                // MARK: - View Action

            case .view(.viewDidAppear):
                state.summaryRetryCount = 0
                state.viewState = .saving
                return .run { send in
                    try? await Task.sleep(for: .seconds(10))
                    await send(.workoutSavedTimeout)
                }
                .cancellable(id: SummaryFeatureCancelID.savingTimeout, cancelInFlight: true)

            case .view(.closeButtonTapped):
                let retryCount = state.summaryRetryCount
                return .run { _ in
                    await WorkoutFileLogger.shared.log("SUMMARY CLOSE — user dismissed failed view after \(retryCount) attempts")
                    await self.dismiss()
                }

            case .view(.endWorkoutButtonTapped):

                let trainingSession = state.trainingSession
                let resultInputs = state.resultInputs
                let hkWorkoutId = state.summary?.workout?.uuid
                let hrBuffer = state.hrBuffer
                let phaseTimestamps = state.phaseTimestamps
                let now = Date()

                return .run { [exerciseLogClient, workoutPlanScoreClient] send in
                    // 1. Save WorkoutPlanScore (existing logic)
                    var scoreId: UUID?
                    if let session = trainingSession, let workoutId = hkWorkoutId {
                        let score = WorkoutPlanScore(
                            trainingSessionId: session.id,
                            hkWorkoutId: workoutId,
                            results: resultInputs
                        )
                        scoreId = score.id
                        do {
                            try await workoutPlanScoreClient.save(score)
                        } catch {
                            reportIssue(error)
                        }
                    }

                    // 2. Build and save ExerciseLog entries
                    var exerciseLogs: [ExerciseLog] = []
                    for result in resultInputs {
                        // Find matching phase timestamp for this WOD
                        let phase = phaseTimestamps.first { $0.name == result.name }

                        // Calculate per-phase HR
                        let phaseHR: (avg: Double, max: Double)?
                        if let phase {
                            let samples = hrBuffer.filter {
                                $0.date >= phase.start && $0.date <= (phase.end ?? now)
                            }
                            if !samples.isEmpty {
                                let avg = samples.map(\.bpm).reduce(0, +) / Double(samples.count)
                                let maxBpm = samples.map(\.bpm).max() ?? 0
                                phaseHR = (avg, maxBpm)
                            } else {
                                phaseHR = nil
                            }
                        } else if !hrBuffer.isEmpty {
                            // Fallback: use entire workout HR
                            let avg = hrBuffer.map(\.bpm).reduce(0, +) / Double(hrBuffer.count)
                            let maxBpm = hrBuffer.map(\.bpm).max() ?? 0
                            phaseHR = (avg, maxBpm)
                        } else {
                            phaseHR = nil
                        }

                        // Calculate tempoPerRound from WOD score
                        let tempo: Double? = {
                            switch result.scoreResult {
                            case .forTime(let time):
                                let totalRounds = result.exercises.count > 0 ? result.exercises.count : 1
                                return time / Double(totalRounds)
                            default:
                                return nil
                            }
                        }()

                        for exercise in result.exercises {
                            // Calculate volume load
                            let volumeLoad: Double? = {
                                guard let weight = exercise.actualWeight, weight > 0,
                                      let repsStr = exercise.actualReps else { return nil }
                                let totalReps = repsStr.split(separator: "-")
                                    .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
                                    .reduce(0, +)
                                guard totalReps > 0 else { return nil }
                                return Double(totalReps) * weight
                            }()

                            let log = ExerciseLog(
                                date: now,
                                exerciseType: exercise.exerciseType,
                                unmatchedName: exercise.unmatchedName,
                                category: exercise.category,
                                workoutPlanScoreId: scoreId,
                                wodName: result.name,
                                plannedReps: exercise.plannedReps,
                                plannedWeight: exercise.plannedWeight,
                                actualWeight: exercise.actualWeight,
                                actualReps: exercise.actualReps,
                                scaling: exercise.scaling,
                                isPR: exercise.isPR,
                                avgHeartRate: phaseHR?.avg,
                                maxHeartRate: phaseHR?.max,
                                phaseStartDate: phase?.start,
                                phaseEndDate: phase?.end,
                                timeInPhase: phase.map { ($0.end ?? now).timeIntervalSince($0.start) },
                                volumeLoad: volumeLoad,
                                tempoPerRound: tempo,
                                note: exercise.note.isEmpty ? nil : exercise.note,
                                editableUntil: now.addingTimeInterval(12 * 3600)
                            )
                            exerciseLogs.append(log)
                        }
                    }

                    if !exerciseLogs.isEmpty {
                        do {
                            try await exerciseLogClient.save(exerciseLogs)
                        } catch {
                            reportIssue(error)
                        }
                    }

                    // 3. Dismiss
                    await self.dismiss()
                }

            case .view(.discardWorkoutButtonTapped):
                state.discardAlert = .discardWorkout
                return .none

            case .alert(.presented(.confirmDiscard)):
                let workout = state.summary?.workout
                return .run { [client] _ in
                    if let workout {
                        do {
                            try await client.deleteWorkout(workout)
                        } catch {
                            reportIssue(error)
                        }
                    }
                    await self.dismiss()
                }

            case .alert(.dismiss):
                return .none

            case let .view(.toggleResult(index)):
                guard index < state.showResults.count else { return .none }
                state.showResults[index].toggle()
                if !state.showResults[index] {
                    state.showNotes[index] = false
                    state.resultInputs[index].scoreResult = .completed
                    state.resultInputs[index].note = ""
                }
                return .none

            case let .view(.toggleNote(index)):
                guard index < state.showNotes.count else { return .none }
                state.showNotes[index].toggle()
                if !state.showNotes[index] {
                    state.resultInputs[index].note = ""
                }
                return .none

            case let .view(.updateScore(index, text)):
                guard index < state.resultInputs.count else { return .none }
                state.resultInputs[index].scoreResult = .custom(text)
                return .none

            case let .view(.updateNote(index, text)):
                guard index < state.resultInputs.count else { return .none }
                state.resultInputs[index].note = text
                return .none

            case let .view(.openSetInput(wodIndex, _)):
                guard wodIndex < state.resultInputs.count else { return .none }
                let result = state.resultInputs[wodIndex]
                let hasStrengthSets = result.exercises.contains { $0.sets != nil }

                let scoreText: String = {
                    if case .completed = result.scoreResult { return "" }
                    return result.scoreResult.displayString
                }()

                let placeholder: String = {
                    if hasStrengthSets { return String(localized: "Heaviest set (kg)") }
                    switch result.scoreResult {
                    case .amrap:   return String(localized: "Rounds + reps")
                    case .forTime: return String(localized: "Time (mm:ss)")
                    case .timeCap: return String(localized: "Remaining reps")
                    case .forLoad: return String(localized: "Max weight (kg)")
                    case .forReps: return String(localized: "Total reps")
                    default:       return String(localized: "Enter score...")
                    }
                }()

                state.setInput = SetInputFeature.State(
                    wodName: result.name,
                    scoreText: scoreText,
                    scorePlaceholder: placeholder,
                    exercises: result.exercises,
                    wodIndex: wodIndex
                )
                return .none

            case let .view(.updateExerciseWeight(wodIndex, exerciseIndex, text)):
                guard wodIndex < state.resultInputs.count,
                      exerciseIndex < state.resultInputs[wodIndex].exercises.count
                else { return .none }
                state.resultInputs[wodIndex].exercises[exerciseIndex].actualWeight = Double(text)
                return .none

            case let .view(.updateExerciseReps(wodIndex, exerciseIndex, text)):
                guard wodIndex < state.resultInputs.count,
                      exerciseIndex < state.resultInputs[wodIndex].exercises.count
                else { return .none }
                state.resultInputs[wodIndex].exercises[exerciseIndex].actualReps = text.isEmpty ? nil : text
                return .none

            case let .view(.updateExerciseScaling(wodIndex, exerciseIndex, scaling)):
                guard wodIndex < state.resultInputs.count,
                      exerciseIndex < state.resultInputs[wodIndex].exercises.count
                else { return .none }
                state.resultInputs[wodIndex].exercises[exerciseIndex].scaling = scaling
                return .none

            case let .view(.toggleExercisePR(wodIndex, exerciseIndex)):
                guard wodIndex < state.resultInputs.count,
                      exerciseIndex < state.resultInputs[wodIndex].exercises.count
                else { return .none }
                state.resultInputs[wodIndex].exercises[exerciseIndex].isPR.toggle()
                return .none

            case .view(.viewDidDisappear):
                return .merge(
                    .cancel(id: SummaryFeatureCancelID.sessionStateListener),
                    .cancel(id: SummaryFeatureCancelID.retry),
                    .cancel(id: SummaryFeatureCancelID.savingTimeout)
                )

                // MARK: - Set Input

            case .setInput(.dismiss):
                // Write back exercises + score only if user confirmed (tapped Add, not Cancel)
                if let setInput = state.setInput, setInput.confirmed {
                    let w = setInput.wodIndex
                    if w < state.resultInputs.count {
                        state.resultInputs[w].exercises = setInput.exercises
                        // Write back score as .custom(text)
                        if !setInput.scoreText.isEmpty {
                            state.resultInputs[w].scoreResult = .custom(setInput.scoreText)
                        }
                    }
                    if w < state.exercisesEdited.count {
                        state.exercisesEdited[w] = true
                    }
                }
                return .none

            case .setInput:
                return .none
            }
        }
        .ifLet(\.$discardAlert, action: \.alert)
        .ifLet(\.$setInput, action: \.setInput) {
            SetInputFeature()
        }
    }
}

