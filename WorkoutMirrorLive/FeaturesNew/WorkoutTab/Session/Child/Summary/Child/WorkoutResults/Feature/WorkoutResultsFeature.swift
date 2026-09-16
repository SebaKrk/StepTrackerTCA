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

    // MARK: - Dependency

    @Dependency(\.prEntryClient) var prEntryClient
    @Dependency(\.date.now) var now

    // MARK: - State

    @ObservableState
    struct State: Equatable {

        var cards: IdentifiedArrayOf<WODScoringFeature.State> = []

        /// Day of the workout — prefills the date of a suggested PR entry.
        var workoutDate: Date?

        /// Board-history snapshot backing the suggestion checks. A one-shot read
        /// on purpose — a live `@FetchAll` would break this State's Equatable
        /// (shared with the read-only ActivityDetails embed).
        var prEntries: [PREntry] = []

        /// Prefilled PR editor opened from a suggestion card.
        @Presents var prEditor: PREntryEditorFeature.State?

        /// Typed results for the save flow.
        var results: [WorkoutSessionResult] { cards.map(\.result) }

        /// Read-only embeds (ActivityDetails) never suggest.
        var isEditable: Bool { !cards.allSatisfy(\.isReadOnly) }

        /// "Add to the PR Board" candidates. Stored, not computed — recomputed
        /// in the reducer only when a card commits or the snapshot refreshes,
        /// never on the per-keystroke render path (IOS-00128 review).
        var prSuggestions: [PRSuggestion] = []

        /// Results of cards the user confirmed with Done — plan-prefilled set
        /// weights in untouched cards must never masquerade as lifted weights.
        var committedResults: [WorkoutSessionResult] {
            cards.filter { $0.phase == .entered }.map(\.result)
        }
    }

    // MARK: - Action

    @CasePathable
    enum Action: ViewAction {

        /// Per-card scoring actions (existing behavior).
        case cards(IdentifiedActionOf<WODScoringFeature>)

        /// Presentation actions of the prefilled PR editor sheet.
        case prEditor(PresentationAction<PREntryEditorFeature.Action>)

        /// Parent-sent trigger: cards just became editable (the view's one-shot
        /// `.task` can fire before they exist and must not be the only path).
        case loadPRSnapshot

        /// Fresh board snapshot (on appear and after the editor closes).
        case prEntriesLoaded([PREntry])

        /// Actions sent by the view.
        case view(View)

        @CasePathable
        enum View {

            /// Loads the board snapshot when the section appears.
            case task

            /// Opens the prefilled PR editor for one suggestion.
            case prSuggestionTapped(PRSuggestion)
        }
    }

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .view(.task), .loadPRSnapshot:
                guard state.isEditable else { return .none }
                return loadEntries()

            case let .view(.prSuggestionTapped(suggestion)):
                state.prEditor = PREntryEditorFeature.State(
                    movement: suggestion.movement,
                    now: now,
                    prefilledKilograms: suggestion.kilograms,
                    prefilledDate: state.workoutDate,
                    prefilledContext: .inWod
                )
                return .none

            case .prEditor(.dismiss):
                // Re-check after a possible save — a beaten suggestion vanishes.
                return loadEntries()

            case let .prEntriesLoaded(entries):
                state.prEntries = entries
                recomputeSuggestions(&state)
                return .none

            // The forEach child ran first, so the card's phase is already
            // updated when these commit/reopen actions reach this reducer.
            case .cards(.element(id: _, action: .view(.doneTapped))),
                 .cards(.element(id: _, action: .view(.startEditingTapped))):
                recomputeSuggestions(&state)
                return .none

            case .cards, .prEditor:
                return .none
            }
        }
        .forEach(\.cards, action: \.cards) {
            WODScoringFeature()
        }
        .ifLet(\.$prEditor, action: \.prEditor) {
            PREntryEditorFeature()
        }
    }

    private func loadEntries() -> Effect<Action> {
        .run { [prEntryClient] send in
            // Suggestions are optional sugar — a failed read stays silent.
            let entries = (try? await prEntryClient.fetchAll()) ?? []
            await send(.prEntriesLoaded(entries))
        }
    }

    private func recomputeSuggestions(_ state: inout State) {
        state.prSuggestions = state.isEditable
            ? PRSuggestionBuilder.suggestions(results: state.committedResults, entries: state.prEntries)
            : []
    }
}

// MARK: - Factories

extension WorkoutResultsFeature.State {

    /// Editable cards for the Summary screen. `existingResults` (edit flow from
    /// History) reuses saved results; otherwise fresh results are built from the plan.
    static func editable(
        trainingSession: TrainingSession,
        existingResults: [WorkoutSessionResult]? = nil,
        workoutDate: Date? = nil
    ) -> Self {
        let workouts = trainingSession.workouts
        let wasScored = existingResults != nil
        let results = existingResults ?? freshResults(from: workouts)
        var state = Self()
        state.workoutDate = workoutDate
        state.cards = IdentifiedArrayOf(
            uniqueElements: results.enumerated().map { index, result in
                let workout = workouts.indices.contains(index) ? workouts[index] : nil
                return WODScoringFeature.State(
                    wodIndex: index,
                    result: result,
                    wodType: workout?.type,
                    capMinutes: workout?.timeCap,
                    rounds: workout?.rounds,
                    wasScored: wasScored
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
                WODScoringFeature.State(wodIndex: index, result: result, isReadOnly: true, wasScored: true)
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
                // Strength → structured plannedSets (reps×weight). Mobility → per-set
                // rows too, but reps-only and never round-derived. Everything else
                // (For Time / AMRAP / EMOM / Tabata) → one value field per exercise.
                let sets: [SetEntry]? = {
                    if isStrength(workout.type) {
                        if let planned = exercise.plannedSets, !planned.isEmpty {
                            return planned.map {
                                SetEntry(reps: $0.reps, weight: $0.suggestedWeight)
                            }
                        }
                        guard let rounds = workout.rounds else { return nil }
                        let reps: Int
                        if case let .reps(r) = exercise.target { reps = r } else { reps = 0 }
                        return (0..<rounds).map { _ in SetEntry(reps: reps) }
                    }

                    if workout.type == .mobility,
                       let planned = exercise.plannedSets, !planned.isEmpty {
                        return planned.map { SetEntry(reps: $0.reps, weight: $0.suggestedWeight) }
                    }

                    return nil
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
                    // Tabata's total-reps field starts empty (the plan holds an
                    // interval, not a rep total); other single-field types prefill.
                    actualReps: (sets == nil && workout.type != .tabata) ? exercise.target?.compactString : nil,
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
