//
//  WODScoringFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 27/06/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

/// One result card in the "Wyniki" section: holds the WOD's `result` plus the
/// card state machine (phase, completed/DNF status, drafts). The typed
/// `WodScoreResult` is built exclusively in `doneTapped` per the entry matrix;
/// drafts live beside the result so switching status never loses data (R-b).
@Reducer
struct WODScoringFeature {

    // MARK: - Card model

    /// Card lifecycle: plan visible with an empty score slot → inline editing →
    /// typed result frozen. The typed `WodScoreResult` is built ONLY in `doneTapped`.
    enum CardPhase: Equatable {
        case empty
        case editing
        case entered
    }

    /// Completed/not-finished segment (For Time with a cap only). Lives BESIDE
    /// the drafts — switching it never clears entered data (rule R-b).
    enum WodStatus: Equatable {
        case completed
        case notFinished
    }

    /// Note row lifecycle; the text itself lives in `result.note`.
    enum NoteRowState: Equatable {
        case empty
        case editing
        case saved
    }

    // MARK: - State

    @ObservableState
    struct State: Equatable, Identifiable {

        /// Stable index z `trainingSession.workouts[index]`. Source of truth dla `id`.
        /// Template'y są immutable po stworzeniu workout'u, więc indeks jest stabilny.
        let wodIndex: Int

        /// Wynik tego WOD'a — score, note, lista exercise inputs.
        var result: WorkoutSessionResult

        /// WOD type from the plan; falls back to `derivedWodType` for unplanned results.
        var wodType: ExerciseWorkoutType

        /// Time cap in minutes from the plan's `timeCap` field (never parsed from text).
        var capMinutes: Int?

        /// ActivityDetails renders cards without editing affordances.
        var isReadOnly: Bool = false

        var phase: CardPhase = .empty
        var wodStatus: WodStatus = .completed

        // Drafts live beside the result and survive status switches (rule R-b).
        var draftMinutes: Int = 0
        var draftSeconds: Int = 0
        var dnfRounds: Int = 0
        var dnfExtraReps: Int = 0
        var noteState: NoteRowState = .empty

        var id: Int { wodIndex }

        var draftTotalSeconds: Int { draftMinutes * 60 + draftSeconds }

        /// Rule R-a: soft cap validation — suggests "Nieukończony", never blocks.
        var exceedsCap: Bool {
            guard wodType == .forTime, let capMinutes, wodStatus == .completed else { return false }
            return draftTotalSeconds > capMinutes * 60
        }

        /// Read-only DNF heuristic: an `.amrap` score on a For Time WOD means the
        /// cap cut the workout off (a real AMRAP has `wodType == .amrap`).
        var isDNF: Bool {
            guard case .amrap = result.scoreResult else { return false }
            return wodType == .forTime || result.parsedDescription.timeCap != nil
        }

        init(
            wodIndex: Int,
            result: WorkoutSessionResult,
            wodType: ExerciseWorkoutType? = nil,
            capMinutes: Int? = nil,
            isReadOnly: Bool = false
        ) {
            self.wodIndex = wodIndex
            self.result = result
            self.wodType = wodType ?? result.derivedWodType
            self.capMinutes = capMinutes
            self.isReadOnly = isReadOnly
            self.phase = result.scoreResult == .completed ? .empty : .entered
            self.noteState = result.note.isEmpty ? .empty : .saved
            if case let .amrap(rounds, extraReps) = result.scoreResult,
               self.wodType == .forTime {
                self.wodStatus = .notFinished
                self.dnfRounds = rounds
                self.dnfExtraReps = extraReps
            }
        }
    }

    // MARK: - Action

    @CasePathable
    enum Action: ViewAction {

        case view(View)

        @CasePathable
        enum View {

            /// Opens inline editing (`phase → .editing`) and seeds drafts from the current result.
            case startEditingTapped

            /// Builds the typed `WodScoreResult` per the entry matrix; empty input
            /// returns the card to the empty slot (rule R-c).
            case doneTapped

            /// Completed/Nieukończony segment change — touches ONLY `wodStatus`, drafts survive (R-b).
            case setStatus(WodStatus)

            /// Rule R-a hint action ("Oznaczyć jako Nieukończony?") shown when the draft time exceeds the cap.
            case markNotFinishedFromHint

            /// DNF/AMRAP tiles — completed rounds stepper.
            case updateRounds(Int)

            /// DNF/AMRAP tiles — extra reps stepper.
            case updateExtraReps(Int)

            /// For Time mm:ss picker — minutes wheel (clamped to the cap).
            case updateDraftMinutes(Int)

            /// For Time mm:ss picker — seconds wheel (0–59).
            case updateDraftSeconds(Int)

            /// Strength set table inline editing — reps cell of one set.
            case updateSetReps(exerciseIndex: Int, setIndex: Int, text: String)

            /// Strength set table inline editing — weight cell of one set.
            case updateSetWeight(exerciseIndex: Int, setIndex: Int, text: String)

            /// Per-exercise actual reps field (non-set-based exercises).
            case updateExerciseReps(exerciseIndex: Int, text: String)

            /// Per-exercise actual weight field (non-set-based exercises).
            case updateExerciseWeight(exerciseIndex: Int, text: String)

            /// "+ Dodaj notatkę" — opens the note field.
            case addNoteTapped

            /// Live note text updates (text lives in `result.note`).
            case updateNote(String)

            /// Keyboard Done — freezes the note row (never clears the text).
            case commitNote

            /// Tap on a saved note re-opens editing.
            case savedNoteTapped
        }
    }

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case .view(.startEditingTapped):
                guard !state.isReadOnly else { return .none }
                state.phase = .editing
                switch state.result.scoreResult {
                case let .forTime(time):
                    state.draftMinutes = Int(time) / 60
                    state.draftSeconds = Int(time) % 60
                case let .amrap(rounds, extraReps):
                    state.dnfRounds = rounds
                    state.dnfExtraReps = extraReps
                default:
                    // Fresh For Time entry seeds the picker at the cap so the user
                    // scrolls DOWN to their finish time (fewer taps than from 0:00).
                    if state.wodType == .forTime, let cap = state.capMinutes {
                        state.draftMinutes = cap
                        state.draftSeconds = 0
                    }
                }
                return .none

            case .view(.doneTapped):
                switch (state.wodType, state.wodStatus) {
                case (.strength, _), (.olympicWeightlifting, _):
                    let setWeights = state.result.exercises.flatMap { $0.sets ?? [] }.compactMap(\.weight)
                    let singleWeights = state.result.exercises.compactMap(\.actualWeight)
                    let maxWeight = (setWeights + singleWeights).max()
                    state.result.scoreResult = maxWeight.map { .forLoad(weight: $0) } ?? .completed
                    state.phase = maxWeight == nil ? .empty : .entered

                case (.forTime, .completed):
                    let seconds = state.draftTotalSeconds
                    state.result.scoreResult = seconds > 0 ? .forTime(time: TimeInterval(seconds)) : .completed
                    state.phase = seconds > 0 ? .entered : .empty

                case (.forTime, .notFinished):
                    state.result.scoreResult = .amrap(rounds: state.dnfRounds, extraReps: state.dnfExtraReps)
                    state.phase = .entered

                case (.amrap, _):
                    let hasScore = state.dnfRounds > 0 || state.dnfExtraReps > 0
                    state.result.scoreResult = hasScore
                        ? .amrap(rounds: state.dnfRounds, extraReps: state.dnfExtraReps)
                        : .completed
                    state.phase = hasScore ? .entered : .empty

                default: // emom, tabata — confirmation only
                    state.result.scoreResult = .completed
                    state.phase = .entered
                }
                return .none

            case let .view(.setStatus(status)):
                state.wodStatus = status
                return .none

            case .view(.markNotFinishedFromHint):
                state.wodStatus = .notFinished
                return .none

            case let .view(.updateRounds(rounds)):
                state.dnfRounds = max(0, rounds)
                return .none

            case let .view(.updateExtraReps(reps)):
                state.dnfExtraReps = max(0, reps)
                return .none

            case let .view(.updateDraftMinutes(minutes)):
                state.draftMinutes = min(max(0, minutes), state.capMinutes ?? 99)
                return .none

            case let .view(.updateDraftSeconds(seconds)):
                state.draftSeconds = min(max(0, seconds), 59)
                return .none

            case let .view(.updateSetReps(exerciseIndex, setIndex, text)):
                guard state.result.exercises.indices.contains(exerciseIndex),
                      var sets = state.result.exercises[exerciseIndex].sets,
                      sets.indices.contains(setIndex)
                else { return .none }
                sets[setIndex].reps = Int(text) ?? 0
                state.result.exercises[exerciseIndex].sets = sets
                return .none

            case let .view(.updateSetWeight(exerciseIndex, setIndex, text)):
                guard state.result.exercises.indices.contains(exerciseIndex),
                      var sets = state.result.exercises[exerciseIndex].sets,
                      sets.indices.contains(setIndex)
                else { return .none }
                sets[setIndex].weight = Double(text.replacingOccurrences(of: ",", with: "."))
                state.result.exercises[exerciseIndex].sets = sets
                return .none

            case let .view(.updateExerciseReps(exerciseIndex, text)):
                guard state.result.exercises.indices.contains(exerciseIndex) else { return .none }
                state.result.exercises[exerciseIndex].actualReps = text.isEmpty ? nil : text
                return .none

            case let .view(.updateExerciseWeight(exerciseIndex, text)):
                guard state.result.exercises.indices.contains(exerciseIndex) else { return .none }
                state.result.exercises[exerciseIndex].actualWeight
                    = Double(text.replacingOccurrences(of: ",", with: "."))
                return .none

            case .view(.addNoteTapped):
                guard !state.isReadOnly else { return .none }
                state.noteState = .editing
                return .none

            case let .view(.updateNote(text)):
                state.result.note = text
                return .none

            case .view(.commitNote):
                // Collapsing never clears the text (old "defensive reset" bug).
                state.noteState = state.result.note.isEmpty ? .empty : .saved
                return .none

            case .view(.savedNoteTapped):
                guard !state.isReadOnly else { return .none }
                state.noteState = .editing
                return .none
            }
        }
    }
}
