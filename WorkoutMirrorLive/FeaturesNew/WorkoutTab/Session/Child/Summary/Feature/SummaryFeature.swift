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
                let results = workouts.map { workout -> WorkoutSessionResult in
                    let exercises = workout.exercises.map { exercise in
                        // For Strength/Olympic WODs → use AI-provided structured plannedSets,
                        // fallback to rounds-based default sets if AI didn't deliver them.
                        let sets: [SetEntry]? = {
                            guard isStrength(workout.type) else { return nil }

                            // Path 1: AI-provided structured sets (PRIMARY)
                            if let planned = exercise.plannedSets, !planned.isEmpty {
                                return planned.map {
                                    SetEntry(reps: $0.reps, weight: $0.suggestedWeight)
                                }
                            }

                            // Path 2: Fallback — simple rounds count
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
                state.wodScorings = IdentifiedArrayOf(
                    uniqueElements: results.enumerated().map { index, result in
                        WODScoringFeature.State(wodIndex: index, result: result)
                    }
                )
                return .none

            case let .setHRData(hrBuffer, phaseTimestamps):
                state.hrBuffer = hrBuffer
                state.phaseTimestamps = phaseTimestamps
                return .none

            case let .setEffortPoints(points, dominantZone):
                state.effortPoints = points
                state.dominantZone = dominantZone
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
                        .send(.delegate(.savedWorkoutFound(workout.uuid)))
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
                    if state.wodScorings.isEmpty {
                        return .send(.setTrainingSession(trainingSession))
                    }
                    return .none
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
                let resultInputs = state.wodScorings.map(\.result)
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

            case let .view(.toggleResult(index)):
                guard var scoring = state.wodScorings[id: index] else { return .none }
                scoring.showResults.toggle()
                if !scoring.showResults {
                    scoring.showNotes = false
                    scoring.result.scoreResult = .completed
                    scoring.result.note = ""
                }
                state.wodScorings[id: index] = scoring
                return .none

            case let .view(.toggleNote(index)):
                guard var scoring = state.wodScorings[id: index] else { return .none }
                scoring.showNotes.toggle()
                if !scoring.showNotes {
                    scoring.result.note = ""
                }
                state.wodScorings[id: index] = scoring
                return .none

            case let .view(.updateScore(index, text)):
                guard var scoring = state.wodScorings[id: index] else { return .none }
                scoring.result.scoreResult = .custom(text)
                state.wodScorings[id: index] = scoring
                return .none

            case let .view(.updateNote(index, text)):
                guard var scoring = state.wodScorings[id: index] else { return .none }
                scoring.result.note = text
                state.wodScorings[id: index] = scoring
                return .none

            case let .view(.openSetInput(wodIndex, _)):
                guard let scoring = state.wodScorings[id: wodIndex] else { return .none }
                let result = scoring.result

                let scoreText: String = {
                    if case .completed = result.scoreResult { return "" }
                    return result.scoreResult.displayString
                }()

                // Get WOD type from training session
                let workouts = state.trainingSession?.workouts ?? []
                let wodType = wodIndex < workouts.count ? workouts[wodIndex].type : .forTime

                state.setInput = SetInputFeature.State(
                    wodName: result.name,
                    scoreText: scoreText,
                    scorePlaceholder: "",
                    exercises: result.exercises,
                    wodType: wodType,
                    wodIndex: wodIndex
                )
                return .none

            case let .view(.updateExerciseWeight(wodIndex, exerciseIndex, text)):
                guard var scoring = state.wodScorings[id: wodIndex],
                      exerciseIndex < scoring.result.exercises.count
                else { return .none }
                scoring.result.exercises[exerciseIndex].actualWeight = Double(text)
                state.wodScorings[id: wodIndex] = scoring
                return .none

            case let .view(.updateExerciseReps(wodIndex, exerciseIndex, text)):
                guard var scoring = state.wodScorings[id: wodIndex],
                      exerciseIndex < scoring.result.exercises.count
                else { return .none }
                scoring.result.exercises[exerciseIndex].actualReps = text.isEmpty ? nil : text
                state.wodScorings[id: wodIndex] = scoring
                return .none

            case let .view(.updateExerciseScaling(wodIndex, exerciseIndex, scaling)):
                guard var scoring = state.wodScorings[id: wodIndex],
                      exerciseIndex < scoring.result.exercises.count
                else { return .none }
                scoring.result.exercises[exerciseIndex].scaling = scaling
                state.wodScorings[id: wodIndex] = scoring
                return .none

            case let .view(.toggleExercisePR(wodIndex, exerciseIndex)):
                guard var scoring = state.wodScorings[id: wodIndex],
                      exerciseIndex < scoring.result.exercises.count
                else { return .none }
                scoring.result.exercises[exerciseIndex].isPR.toggle()
                state.wodScorings[id: wodIndex] = scoring
                return .none

            case .view(.viewDidDisappear):
                return .merge(
                    .cancel(id: SummaryFeatureCancelID.sessionStateListener),
                    .cancel(id: SummaryFeatureCancelID.retry)
                )

                // MARK: - Set Input

            case .setInput(.dismiss):
                // Write back exercises + score only if user confirmed (tapped Add, not Cancel)
                if let setInput = state.setInput, setInput.confirmed {
                    let w = setInput.wodIndex
                    if var scoring = state.wodScorings[id: w] {
                        scoring.result.exercises = setInput.exercises
                        // Parse score into typed WodScoreResult based on WOD type
                        scoring.result.scoreResult = parseScore(
                            text: setInput.scoreText,
                            wodType: setInput.wodType,
                            exercises: setInput.exercises
                        )
                        scoring.exercisesEdited = true
                        state.wodScorings[id: w] = scoring
                    }
                }
                return .none

            case .setInput:
                return .none

                // MARK: - WOD Scorings (child feature)

                // Delegate: child WODScoring wants to open SetInputSheet → parent presents it.
            case let .wodScorings(.element(id: _, action: .delegate(.requestEditExercises(wodIndex)))):
                guard let scoring = state.wodScorings[id: wodIndex] else { return .none }
                let result = scoring.result
                let scoreText: String = {
                    if case .completed = result.scoreResult { return "" }
                    return result.scoreResult.displayString
                }()
                let workouts = state.trainingSession?.workouts ?? []
                let wodType = wodIndex < workouts.count ? workouts[wodIndex].type : .forTime
                state.setInput = SetInputFeature.State(
                    wodName: result.name,
                    scoreText: scoreText,
                    scorePlaceholder: "",
                    exercises: result.exercises,
                    wodType: wodType,
                    wodIndex: wodIndex
                )
                return .none

            case .wodScorings:
                // Remaining child actions (binding, toggle) — the child reducer handles them itself.
                return .none
            }
        }
        .forEach(\.wodScorings, action: \.wodScorings) {
            WODScoringFeature()
        }
        .ifLet(\.$discardAlert, action: \.alert)
        .ifLet(\.$errorAlert, action: \.errorAlert)
        .ifLet(\.$setInput, action: \.setInput) {
            SetInputFeature()
        }
    }

    // MARK: - Helpers

    /// Parses user input into a typed `WodScoreResult` based on WOD type.
    ///
    /// - Strength/Olympic: auto-computes `.forLoad` from max set weight (ignores text)
    /// - AMRAP: parses "6+14" → `.amrap(rounds: 6, extraReps: 14)`
    /// - FOR TIME: parses "14:32" → `.forTime(time: 872)`
    /// - EMOM/Tabata: `.completed`
    /// - Fallback: `.custom(text)`
    private func parseScore(
        text: String,
        wodType: ExerciseWorkoutType,
        exercises: [ExerciseLogInput]
    ) -> WodScoreResult {
        switch wodType {
        case .strength, .olympicWeightlifting:
            let setWeights = exercises.flatMap { $0.sets ?? [] }.compactMap(\.weight)
            let singleWeights = exercises.compactMap(\.actualWeight)
            let maxWeight = (setWeights + singleWeights).max() ?? 0
            return .forLoad(weight: maxWeight)

        case .amrap:
            let parts = text.split(separator: "+").map { $0.trimmingCharacters(in: .whitespaces) }
            if let rounds = parts.first.flatMap({ Int($0) }) {
                let extraReps = parts.count > 1 ? Int(parts[1]) ?? 0 : 0
                return .amrap(rounds: rounds, extraReps: extraReps)
            }
            return text.isEmpty ? .completed : .custom(text)

        case .forTime:
            let parts = text.split(separator: ":").map { $0.trimmingCharacters(in: .whitespaces) }
            if let minutes = parts.first.flatMap({ Int($0) }) {
                let seconds = parts.count > 1 ? Int(parts[1]) ?? 0 : 0
                return .forTime(time: TimeInterval(minutes * 60 + seconds))
            }
            return text.isEmpty ? .completed : .custom(text)

        case .emom, .tabata:
            return .completed
        }
    }
}

