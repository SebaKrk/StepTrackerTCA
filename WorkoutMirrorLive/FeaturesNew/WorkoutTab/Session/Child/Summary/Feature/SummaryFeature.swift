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
                state.resultInputs = workouts.map { WorkoutSessionResult(name: $0.name, description: $0.snapshotDescription) }
                state.showResults = Array(repeating: false, count: workouts.count)
                state.showNotes = Array(repeating: false, count: workouts.count)
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
                return .run { send in
                    if let session = trainingSession, let workoutId = hkWorkoutId {
                        let score = WorkoutPlanScore(
                            trainingSessionId: session.id,
                            hkWorkoutId: workoutId,
                            results: resultInputs
                        )
                        do {
                            try await workoutPlanScoreClient.save(score)
                        } catch {
                            reportIssue(error)
                        }
                    }
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
                    state.resultInputs[index].score = ""
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
                state.resultInputs[index].score = text
                return .none

            case let .view(.updateNote(index, text)):
                guard index < state.resultInputs.count else { return .none }
                state.resultInputs[index].note = text
                return .none

            case .view(.viewDidDisappear):
                return .merge(
                    .cancel(id: SummaryFeatureCancelID.sessionStateListener),
                    .cancel(id: SummaryFeatureCancelID.retry),
                    .cancel(id: SummaryFeatureCancelID.savingTimeout)
                )
            }
        }
        .ifLet(\.$discardAlert, action: \.alert)
    }
}

