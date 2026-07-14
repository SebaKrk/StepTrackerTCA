//
//  ActivityPlanScoreFeature.swift
//  WorkoutMirrorLive
//

import ComposableArchitecture
import Foundation
import SharedModels

/// Minimal child feature that loads a single `WorkoutPlanScore` for a specific HKWorkout.
///
/// Used in `ActivityDetailsFeature` to display WOD results when a workout was executed
/// according to a training plan.
@Reducer
struct ActivityPlanScoreFeature {

    // MARK: - Dependency

    @Dependency(\.workoutPlanScoreClient) var client
    @Dependency(\.exerciseLogClient) var exerciseLogClient
    @Dependency(\.date.now) var now

    // MARK: - State

    @ObservableState
    struct State {

        /// The HKWorkout UUID used to look up the associated training plan score.
        var hkWorkoutId: UUID

        /// Current loading state of the WOD results.
        var loadState: LoadState = .loading

        /// All `ExerciseLog`s linked to the loaded `WorkoutPlanScore`.
        /// Used to (a) decide whether each WOD is still editable, (b) populate the
        /// edit sheet with current values.
        var exerciseLogs: [ExerciseLog] = []

        /// Per-set edit sheet — presented when user taps "Edytuj" on a WOD card.
        @Presents var setInput: SetInputFeature.State?
    }

    // MARK: - Action

    @CasePathable
    enum Action {

        /// Triggers a fetch of the WOD score for `hkWorkoutId`.
        case fetchScore

        /// Fetch completed. `nil` means no plan was associated with this workout.
        case scoreFetched(WorkoutPlanScore?)

        /// Fetch failed — `reportIssue` was called with the underlying error.
        case scoreFetchFailed

        /// ExerciseLogs for this workout were loaded.
        case exerciseLogsLoaded([ExerciseLog])

        /// User tapped "Edytuj" on the WOD at the given index in `score.results`.
        case editTapped(wodIndex: Int)

        /// User tapped the pending-results container — asks the parent to open the
        /// fill-in flow (the parent owns the manual-entry navigation).
        case fillResultsTapped

        /// Presentation action for the per-set edit sheet.
        case setInput(PresentationAction<SetInputFeature.Action>)

        /// Actions the parent (`ActivityDetailsFeature`) observes.
        case delegate(Delegate)

        @CasePathable
        enum Delegate {

            /// User wants to fill in the (still empty) results of the linked plan.
            case fillResultsTapped
        }
    }

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case .fetchScore:
                state.loadState = .loading
                return .run { [id = state.hkWorkoutId] send in
                    do {
                        let score = try await client.fetchByHKWorkoutId(id)
                        await send(.scoreFetched(score))
                    } catch {
                        reportIssue(error)
                        await send(.scoreFetchFailed)
                    }
                }

            case let .scoreFetched(score):
                state.loadState = score.map { .loaded($0) } ?? .notFound
                guard let score else { return .none }
                return .run { [exerciseLogClient] send in
                    do {
                        let logs = try await exerciseLogClient.fetchByWorkoutPlanScoreId(score.id)
                        await send(.exerciseLogsLoaded(logs))
                    } catch {
                        reportIssue(error)
                    }
                }

            case .scoreFetchFailed:
                state.loadState = .failed
                return .none

            case let .exerciseLogsLoaded(logs):
                state.exerciseLogs = logs
                return .none

            case .fillResultsTapped:
                return .send(.delegate(.fillResultsTapped))

            case .delegate:
                return .none

            case let .editTapped(wodIndex):
                guard case let .loaded(score) = state.loadState,
                      score.results.indices.contains(wodIndex) else { return .none }
                let result = score.results[wodIndex]
                // Filter by strict UUID match; fall back to wodName for legacy logs only.
                let logsForWod = state.exerciseLogs.filter { log in
                    if let resultId = log.workoutSessionResultId {
                        return resultId == result.id
                    }
                    return log.wodName == result.name
                }
                let inputs = logsForWod.map { ExerciseLogInput(from: $0) }
                state.setInput = SetInputFeature.State(
                    wodName: result.name,
                    scoreText: result.scoreResult.displayString,
                    scorePlaceholder: "",
                    exercises: inputs,
                    wodType: Self.wodType(from: result.scoreResult),
                    wodIndex: wodIndex
                )
                return .none

            case .setInput(.dismiss):
                // Write back only if user confirmed (tapped Add, not Cancel).
                guard let setInput = state.setInput, setInput.confirmed,
                      case let .loaded(score) = state.loadState,
                      score.results.indices.contains(setInput.wodIndex) else {
                    return .none
                }

                // 1. Update ExerciseLogs (per-exercise actuals).
                let merged = mergeUpdatedInputs(setInput.exercises, into: state.exerciseLogs)
                state.exerciseLogs = merged
                let editable = merged.filter { $0.isEditable(now: now) }

                // 2. Update WorkoutPlanScore (WOD-level score, e.g. "16:00").
                var updatedScore = score
                updatedScore.results[setInput.wodIndex].scoreResult = Self.parseScore(
                    text: setInput.scoreText,
                    wodType: setInput.wodType,
                    exercises: setInput.exercises
                )
                state.loadState = .loaded(updatedScore)

                return .run { [exerciseLogClient, client] _ in
                    if !editable.isEmpty {
                        do {
                            try await exerciseLogClient.save(editable)
                        } catch {
                            reportIssue(error)
                        }
                    }
                    do {
                        try await client.save(updatedScore)
                    } catch {
                        reportIssue(error)
                    }
                }

            case .setInput:
                return .none
            }
        }
        .ifLet(\.$setInput, action: \.setInput) {
            SetInputFeature()
        }
    }

    // MARK: - Helpers

    /// Replaces matching ExerciseLogs by id with values from updated inputs.
    /// Mutates user-editable fields (`actualWeight`, `actualReps`, `scaling`, `isPR`,
    /// `note`, `sets`) — HR/timestamps/derived fields stay intact.
    ///
    /// For per-set strength workouts the legacy single-value mirrors
    /// (`actualWeight` / `actualReps`) are **always** recomputed from the current
    /// `sets`. Falling back to the input's prefilled `actualWeight` would leak
    /// stale values from the first save — the SetInputView only mutates `sets[i]`,
    /// so the input still carries the old prefill.
    private func mergeUpdatedInputs(_ inputs: [ExerciseLogInput], into logs: [ExerciseLog]) -> [ExerciseLog] {
        let inputById = Dictionary(uniqueKeysWithValues: inputs.map { ($0.id, $0) })
        return logs.map { log in
            guard let input = inputById[log.id] else { return log }
            var copy = log
            if let sets = input.sets, !sets.isEmpty {
                copy.sets = sets
                copy.actualWeight = sets.compactMap(\.weight).max()
                copy.actualReps = sets.map { "\($0.reps)" }.joined(separator: "-")
            } else {
                copy.sets = input.sets
                copy.actualWeight = input.actualWeight
                copy.actualReps = input.actualReps
            }
            copy.scaling = input.scaling
            copy.isPR = input.isPR
            copy.note = input.note.isEmpty ? nil : input.note
            return copy
        }
    }

    /// Approximates the WOD type from the saved `WodScoreResult` for the edit sheet.
    /// Used when we don't have access to the original `TrainingSession` (post-workout edit).
    private static func wodType(from score: WodScoreResult) -> ExerciseWorkoutType {
        switch score {
        case .forTime, .timeCap: return .forTime
        case .amrap:             return .amrap
        case .forLoad:           return .strength
        case .forReps:           return .forTime
        case .completed, .custom: return .forTime
        }
    }

    /// Parses user-entered text into a typed `WodScoreResult` based on the WOD type.
    /// Mirrors `SummaryFeature.parseScore` — kept in sync to ensure identical semantics.
    private static func parseScore(
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

// MARK: - LoadState

extension ActivityPlanScoreFeature {

    /// Represents the possible states of the WOD results fetch.
    enum LoadState: Equatable {

        /// Fetch is in progress.
        case loading

        /// Score found — workout was executed according to a training plan.
        case loaded(WorkoutPlanScore)

        /// No score found — workout had no associated plan. Nothing is displayed.
        case notFound

        /// Fetch failed — error was reported via `reportIssue`. Nothing is displayed.
        case failed

    }

}
