//
//  SummaryFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 30/08/2025.
//

import ComposableArchitecture
import HealthHub
import HealthKit
import IssueReporting
import SharedModels
import Foundation

@Reducer
struct SummaryFeature {

    /// Bounded local retry for the iPhone-standalone happy path — covers the brief
    /// race between `finishWorkout()` and the router-cache broadcast. This is NOT
    /// a cross-device wait; the watch-primary machinery (10s `.workoutSaved` timeout
    /// + 40×3s HealthKit poll) was removed in IOS-00098-E.
    static let maxSummaryAttempts = 5

    // MARK: - Dependency

    @Dependency(\.sessionClient) var client
    @Dependency(\.workoutPlanScoreClient) var workoutPlanScoreClient
    @Dependency(\.exerciseLogClient) var exerciseLogClient
    @Dependency(\.effortScoreClient) var effortScoreClient
    @Dependency(\.maxHeartRateClient) var maxHeartRateClient
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.uuid) var uuid
    @Dependency(\.date.now) var now

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Scope(state: \.results, action: \.results) {
            WorkoutResultsFeature()
        }
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
                state.results = trainingSession.map { .editable(trainingSession: $0) } ?? .init()
                return .none

            case let .setHRData(hrBuffer, phaseTimestamps):
                state.hrBuffer = hrBuffer
                state.hrMinuteRanges = HRMinuteRange.from(buffer: hrBuffer)
                state.phaseTimestamps = phaseTimestamps
                return .none

            case let .setEffortPoints(points, secondsByZone):
                state.effortPoints = points
                state.secondsByZone = secondsByZone
                return .none

            case let .setUserMaxHeartRate(maxHR):
                state.userMaxHeartRate = maxHR
                return .none

            case .delegate:
                return .none

            case let .summaryLoaded(summary):
                state.summary = summary
                let resultLog = summary.workout.map { "found: \($0.uuid)" } ?? "nil"

                if let workout = summary.workout {
                    state.viewState = .successfullyLoaded
                    return .merge(
                        .cancel(id: SummaryFeatureCancelID.retry),
                        .run { _ in await WorkoutFileLogger.shared.log("SUMMARY RESULT — workout: \(resultLog)") },
                        // iPhone-standalone: this is the moment the saved HKWorkout
                        // becomes known — hand the uuid up so AppTabNewFeature can
                        // consume PendingEffortScore (no `.workoutSaved` from the
                        // Watch in this mode; persist guards are idempotent).
                        .send(.delegate(.savedWorkoutFound(workout.uuid))),
                        userMaxHeartRateEffect(state)
                    )
                } else if state.summaryRetryCount >= Self.maxSummaryAttempts {
                    // iPhone-standalone only: the workout is saved locally by
                    // iPhoneWorkoutSession, so the router cache should be populated within
                    // a beat — this is a rare edge fallback, not a cross-device wait
                    // (the watch-primary waiting machinery was removed in IOS-00098-E).
                    state.viewState = .failed
                    state.failureDebugInfo += ", workout: \(resultLog), attempts: \(state.summaryRetryCount), metrics: \(summary.metrics)"
                    return .run { [debugInfo = state.failureDebugInfo] _ in
                        await WorkoutFileLogger.shared.log("SUMMARY FAILED — \(debugInfo)")
                    }
                } else {
                    state.viewState = .loading
                    return .merge(
                        .run { _ in await WorkoutFileLogger.shared.log("SUMMARY RESULT — workout: \(resultLog) → will retry in 1s") },
                        .run { send in
                            try? await Task.sleep(for: .milliseconds(1000))
                            await send(.checkSummary)
                        }
                        .cancellable(id: SummaryFeatureCancelID.retry, cancelInFlight: true)
                    )
                }

                // MARK: - View Action

            case .view(.viewDidAppear):
                // Manual entry (from ActivityDetailsFeature): State pre-filled by the `manualEntry(...)`
                // factory, `isManualEntry = true`. We skip the 10s timeout + 40-attempt poll —
                // the workout has existed in HealthKit for a long time. If `resultInputs` is empty (link-new
                // flow with `existingResults: nil`), map from trainingSession — we use the existing
                // `.setTrainingSession` action to avoid duplicating logic.
                if state.isManualEntry, let trainingSession = state.trainingSession {
                    state.viewState = .successfullyLoaded
                    if state.results.cards.isEmpty {
                        return .merge(
                            .send(.setTrainingSession(trainingSession)),
                            manualEntryZonesEffect(state)
                        )
                    }
                    return manualEntryZonesEffect(state)
                }

                // Idempotent onAppear: only the fresh `.loading` entry kicks off loading.
                // A re-appear — or a preview seeded with a decided state (.failed /
                // .successfullyLoaded) — keeps that state instead of resetting to the
                // spinner. Fixes previews showing ProgressView regardless of their name.
                guard state.viewState == .loading else { return .none }

                // Happy path (iPhone-standalone only after IOS-00098-E) — the workout is saved
                // locally by iPhoneWorkoutSession and waits in the router cache. We check right
                // away; a short retry (5×1s) protects against the race between finishWorkout()
                // and the broadcast to the cache — without waiting for any data from the Watch.
                state.summaryRetryCount = 0
                return .send(.checkSummary)

            case .view(.closeButtonTapped):
                let retryCount = state.summaryRetryCount
                return .run { _ in
                    await WorkoutFileLogger.shared.log("SUMMARY CLOSE — user dismissed failed view after \(retryCount) attempts")
                    await self.dismiss()
                }

            case .view(.endWorkoutButtonTapped):

                let trainingSession = state.trainingSession
                let resultInputs = state.results.cards.map(\.result)
                let hkWorkoutId = state.summary?.workout?.uuid
                let workoutForSnapshot = state.summary?.workout
                let hrBuffer = state.hrBuffer
                let phaseTimestamps = state.phaseTimestamps
                let now = self.now

                return .run { [exerciseLogClient, workoutPlanScoreClient, maxHeartRateClient, uuid] send in
                    // 1. Save WorkoutPlanScore (existing logic)
                    var scoreId: UUID?
                    if let session = trainingSession, let workoutId = hkWorkoutId {
                        // Reuse the record created by the app-level plan-link listener
                        // (IOS-00098-C) — a fresh id for the same hkWorkoutId would
                        // duplicate the score row (upsert keys on id, not workout).
                        let existing = try? await workoutPlanScoreClient.fetchByHKWorkoutId(workoutId)
                        let score = WorkoutPlanScore(
                            id: existing?.id ?? uuid(),
                            date: existing?.date ?? now,
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

                            // For Strength (sets), derive actualWeight from max set weight
                            let effectiveWeight: Double? = exercise.actualWeight
                                ?? exercise.sets?.compactMap(\.weight).max()

                            // For Strength (sets), derive actualReps from sets
                            let effectiveReps: String? = exercise.actualReps
                                ?? exercise.sets.map { sets in
                                    sets.map { "\($0.reps)" }.joined(separator: "-")
                                }

                            let log = ExerciseLog(
                                date: now,
                                exerciseType: exercise.exerciseType,
                                unmatchedName: exercise.unmatchedName,
                                category: exercise.category,
                                workoutPlanScoreId: scoreId,
                                workoutSessionResultId: result.id,
                                wodName: result.name,
                                plannedReps: exercise.plannedReps,
                                plannedWeight: exercise.plannedWeight,
                                actualWeight: effectiveWeight,
                                actualReps: effectiveReps,
                                sets: exercise.sets,
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
                                editableUntil: now.addingTimeInterval(72 * 3600)
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

                    // 3. Eager HR snapshot creation (IOS-00097-F).
                    // Snapshot freezes the formula **from the workout day** — regardless of whether
                    // the user ever opens the detail, the formula and maxHR from the moment of save
                    // are preserved forever. `forWorkout` = fetchOrCreate, so for a
                    // workout that already has a snapshot (e.g. manual entry edit) = no-op.
                    if let workout = workoutForSnapshot {
                        _ = await maxHeartRateClient.forWorkout(workout)
                    }

                    // 4. Dismiss
                    await self.dismiss()
                }

            case let .view(.chartMinuteSelected(minute)):
                state.selectedChartMinute = minute
                return .none

            case let .view(.saveButtonVisibilityChanged(isVisible)):
                guard state.isSaveButtonVisible != isVisible else { return .none }
                state.isSaveButtonVisible = isVisible
                return .none

            case .view(.discardWorkoutButtonTapped):
                state.discardAlert = .discardWorkout
                return .none

            case .alert(.presented(.confirmDiscard)):
                guard let workout = state.summary?.workout else {
                    return .run { _ in await self.dismiss() }
                }
                state.isDiscarding = true
                return .run { [client, effortScoreClient] send in
                    do {
                        try await client.deleteWorkout(workout)
                        // The effort score may ALREADY be persisted: in standalone the
                        // `savedWorkoutFound` delegate consumes the pending snapshot as
                        // soon as the summary loads — before the save/discard decision.
                        // A discarded workout must not leave an orphaned score row
                        // (mirrors the delete path in PersonalActivityFeature).
                        try? await effortScoreClient.deleteByHKWorkoutId(workout.uuid)
                        await send(.discardCompleted(errorMessage: nil))
                    } catch {
                        // SessionClient.deleteWorkout already treats HKError.errorNoData
                        // as idempotent success — anything thrown here is a real failure.
                        reportIssue(error)
                        await send(.discardCompleted(errorMessage: error.localizedDescription))
                    }
                }

            case .alert(.dismiss):
                return .none

            case .discardCompleted(errorMessage: nil):
                state.isDiscarding = false
                // Workout discarded → drop the frozen effort snapshot in case it
                // was NOT consumed yet (watchPrimary discard). The standalone path
                // may have persisted it already — that row is removed in the
                // `confirmDiscard` effect; clearing here covers the pending case
                // so it cannot attach to the next workout within 12h.
                @Shared(.pendingEffortScore) var pendingEffortScore
                $pendingEffortScore.withLock { $0 = nil }
                return .run { _ in await self.dismiss() }

            case let .discardCompleted(errorMessage: .some(message)):
                state.isDiscarding = false
                state.errorAlert = AlertState {
                    TextState(String(localized: "Failed to discard workout"))
                } actions: {
                    ButtonState(role: .cancel) {
                        TextState(String(localized: "OK"))
                    }
                } message: {
                    TextState(message)
                }
                return .none

            case .errorAlert:
                // Presentation reducer handles dismiss; nothing to do here.
                return .none

            case .view(.viewDidDisappear):
                return .merge(
                    .cancel(id: SummaryFeatureCancelID.sessionStateListener),
                    .cancel(id: SummaryFeatureCancelID.retry)
                )

                // MARK: - Results (child feature)

            case .results:
                // Remaining card actions — handled inside WorkoutResultsFeature.
                return .none
            }
        }
        .ifLet(\.$discardAlert, action: \.alert)
        .ifLet(\.$errorAlert, action: \.errorAlert)
    }

    // MARK: - Helpers

    /// One-shot fetch of the user's max heart rate (USER max, not session peak).
    private func userMaxHeartRateEffect(_ state: State) -> Effect<Action> {
        guard state.userMaxHeartRate == nil, let workout = state.summary?.workout else {
            return .none
        }
        return .run { send in
            await send(.setUserMaxHeartRate(maxHeartRateClient.forWorkout(workout)))
        }
    }

    /// Manual entry has no live accumulator — hydrate zones from the persisted
    /// effort score, falling back to classifying the raw HR buffer.
    private func manualEntryZonesEffect(_ state: State) -> Effect<Action> {
        guard state.secondsByZone.isEmpty, let workout = state.summary?.workout else {
            return .none
        }
        return .run { [buffer = state.hrBuffer] send in
            let userMax = await maxHeartRateClient.forWorkout(workout)
            await send(.setUserMaxHeartRate(userMax))
            if let score = try? await effortScoreClient.fetchByHKWorkoutId(workout.uuid) {
                await send(.setEffortPoints(points: score.points, secondsByZone: score.secondsByZone))
            } else {
                let zones = HeartRateZone.secondsByZone(from: buffer, maxHR: userMax)
                guard !zones.isEmpty else { return }
                await send(.setEffortPoints(points: 0, secondsByZone: zones))
            }
        }
    }

}
