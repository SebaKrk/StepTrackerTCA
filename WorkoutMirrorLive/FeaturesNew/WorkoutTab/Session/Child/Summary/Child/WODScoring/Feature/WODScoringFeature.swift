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

    /// Which status control the card header carries. `nil` means none at all.
    enum StatusKind: Equatable {

        /// A frozen verdict once the card holds a result.
        case pill(WodStatus)

        /// A live choice between completed and not finished.
        case segment(WodStatus)
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

        /// Planned round count (Tabata rows, "· N rund" chip). `nil` when absent.
        var rounds: Int?

        /// Rep ladder of the block ("10-9-8…1"); when present it derives the reps instead of the user.
        var repScheme: [Int]?

        /// The rounds tiles are capturing an attempt the cap cut short, not a plain score.
        var capturesUnfinished: Bool {
            wodType == .forTime && wodStatus == .notFinished
        }

        /// What this card asks for right now; a capped For Time turns into rounds and
        /// reps the moment it is marked unfinished.
        var scoreEntry: ScoreEntryKind {
            capturesUnfinished ? .roundsAndReps : wodType.scoreEntryKind
        }

        /// The status control the header carries, per the entry matrix.
        ///
        /// Read-only cards freeze the verdict instead of offering the choice again,
        /// and a card with nothing entered yet shows no verdict at all.
        ///
        /// The read-only branch below is unreachable today: `WorkoutResultsFeature.readOnly`
        /// builds cards without a cap, so the `where` never holds. Keep it until that
        /// factory passes the plan through; do not "maintain" it as live behaviour.
        var statusKind: StatusKind? {
            switch wodType {
            case .forTime where capMinutes != nil:
                if isReadOnly { return phase == .entered ? .pill(isDNF ? .notFinished : .completed) : nil }
                return .segment(wodStatus)
            case .forTime, .emom, .tabata, .mobility:
                return phase == .entered ? .pill(.completed) : nil
            case .strength, .olympicWeightlifting, .amrap, .intervals:
                return nil
            }
        }

        /// The ladder owns the reps, so the editor shows them instead of asking for them.
        var ladderDrivesReps: Bool {
            repScheme?.isEmpty == false && wodType == .forTime && wodStatus == .notFinished
        }

        /// Every round holds the same work, so the score tiles imply each movement's total.
        ///
        /// A ladder speaks first where it has something to say: its rounds shrink, and
        /// the flat arithmetic here would read them all as the first rung.
        var roundDrivesReps: Bool {
            guard repScheme?.isEmpty != false else { return false }
            switch wodType {
            case .amrap: return true
            case .forTime: return wodStatus == .notFinished
            default: return false
            }
        }

        /// One round's work per movement in board order; zero where the round does not speak for it.
        var roundSizes: [Int] {
            result.exercises.indices.map { index in
                roundOwns(exerciseAt: index) ? (result.exercises[index].target?.count ?? 0) : 0
            }
        }

        /// Where an unfinished attempt stopped: one past the last movement holding data.
        ///
        /// The card draws its time-limit separator here and mutes what follows, so the
        /// rule belongs beside the result rather than in the view that renders it.
        var dnfCutoffIndex: Int {
            let lastWithData = result.exercises.lastIndex { exercise in
                exercise.actualWeight != nil || exercise.actualReps != nil
            }
            return lastWithData.map { $0 + 1 } ?? result.exercises.count
        }

        /// Movements whose reps the score currently writes.
        ///
        /// A property, not a method: the view reaches state through the store's
        /// key-path lookup, which cannot call one.
        var derivedRepsIndices: Set<Int> {
            Set(result.exercises.indices.filter { index in
                (ladderDrivesReps && ladderOwns(exerciseAt: index)) || roundOwns(exerciseAt: index)
            })
        }

        /// Whether this exercise follows the block's ladder rather than a scheme of its own.
        ///
        /// A movement the ladder speaks for carries no target: the results builder writes
        /// its planned total as a bare number summed from the rungs. One that states a
        /// target of its own means something else and keeps its unit suffix, which after
        /// the save is all that marks calories as calories.
        func ladderOwns(exerciseAt index: Int) -> Bool {
            guard let repScheme, result.exercises.indices.contains(index) else { return false }
            let exercise = result.exercises[index]
            guard exercise.target == nil else { return false }
            return Int(exercise.plannedReps ?? "") == repScheme.reduce(0, +)
        }

        /// Whether this movement's total follows the block's rounds rather than the athlete's typing.
        ///
        /// A movement with written sets carries a total of its own, and a `.rounds` or
        /// `.laps` target counts the block itself rather than the work inside it.
        func roundOwns(exerciseAt index: Int) -> Bool {
            guard roundDrivesReps, result.exercises.indices.contains(index) else { return false }
            let exercise = result.exercises[index]
            guard exercise.sets?.isEmpty != false, let target = exercise.target else { return false }
            switch target {
            case .rounds, .laps:
                return false
            case .reps, .calories, .meters, .seconds, .minutes:
                return target.count > 0
            }
        }

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

        /// A read-only card keeps the note row only when there is a note to read.
        var noteIsHidden: Bool { isReadOnly && noteState != .saved }

        var id: Int { wodIndex }

        var draftTotalSeconds: Int { draftMinutes * 60 + draftSeconds }

        /// Rule R-a: soft cap validation — suggests "Nieukończony", never blocks.
        var exceedsCap: Bool {
            guard wodType == .forTime, let capMinutes, wodStatus == .completed else { return false }
            return draftTotalSeconds > capMinutes * 60
        }

        /// A For Time WOD stored as `.amrap` means the cap cut it off (DNF). A
        /// genuine AMRAP is `wodType == .amrap` and is never a DNF — even though
        /// it also has a time limit, so the cap alone must NOT flag it.
        var isDNF: Bool {
            guard case .amrap = result.scoreResult else { return false }
            return wodType == .forTime
        }

        init(
            wodIndex: Int,
            result: WorkoutSessionResult,
            wodType: ExerciseWorkoutType? = nil,
            capMinutes: Int? = nil,
            rounds: Int? = nil,
            repScheme: [Int]? = nil,
            isReadOnly: Bool = false,
            wasScored: Bool = false
        ) {
            self.wodIndex = wodIndex
            self.result = result
            self.wodType = wodType ?? result.derivedWodType
            self.capMinutes = capMinutes
            self.rounds = rounds
            self.repScheme = repScheme
            self.isReadOnly = isReadOnly
            // `.completed` is ambiguous — both "nothing entered yet" and a
            // confirmed EMOM/Tabata result. `wasScored` (card built from a saved
            // result, not a fresh plan) disambiguates so a saved EMOM/Tabata
            // keeps its ✓ instead of reverting to the empty slot.
            self.phase = (wasScored || result.scoreResult != .completed) ? .entered : .empty
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
            // A read-only card offers no controls, so nothing the view sends may change it.
            // Scoped to `.view` on purpose: a later `.delegate` must not fall under it.
            if case .view = action, state.isReadOnly { return .none }

            switch action {

            case .view(.startEditingTapped):
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
                switch state.scoreEntry {
                case .sets:
                    let setWeights = state.result.exercises.flatMap { $0.sets ?? [] }.compactMap(\.weight)
                    let singleWeights = state.result.exercises.compactMap(\.actualWeight)
                    let maxWeight = (setWeights + singleWeights).max()
                    state.result.scoreResult = maxWeight.map { .forLoad(weight: $0) } ?? .completed
                    state.phase = maxWeight == nil ? .empty : .entered

                case .time:
                    let seconds = state.draftTotalSeconds
                    state.result.scoreResult = seconds > 0 ? .forTime(time: TimeInterval(seconds)) : .completed
                    state.phase = seconds > 0 ? .entered : .empty

                case .roundsAndReps:
                    // A capped For Time keeps its DNF score even at zero — the status
                    // segment has already said the athlete did not finish.
                    let scored = state.dnfRounds > 0 || state.dnfExtraReps > 0 || state.capturesUnfinished
                    state.result.scoreResult = scored
                        ? .amrap(rounds: state.dnfRounds, extraReps: state.dnfExtraReps)
                        : .completed
                    state.phase = scored ? .entered : .empty

                case .totalPerMovement:
                    // The headline is the sum of the per-movement fields — the team board
                    // ranks both formats by total reps. Nothing entered → just confirmed.
                    let total = state.result.exercises.reduce(0) { sum, exercise in
                        sum + (Int((exercise.actualReps ?? "").prefix(while: \.isNumber)) ?? 0)
                    }
                    state.result.scoreResult = total > 0 ? .forReps(reps: total) : .completed
                    state.phase = .entered

                case .confirmation:
                    // Mobility and intervals carry no load and no clock — done means done.
                    state.result.scoreResult = .completed
                    state.phase = .entered
                }
                return .none

            case let .view(.setStatus(status)):
                state.wodStatus = status
                // DNF needs the rounds picker right away — don't make the user
                // hunt for the edit button after flipping the status.
                if status == .notFinished, state.phase != .editing {
                    state.phase = .editing
                }
                // Only the way back is synced: flipping TO not-finished must not
                // stamp an untouched card with the steppers' zeroes.
                if status == .completed { syncDerivedReps(&state) }
                return .none

            case .view(.markNotFinishedFromHint):
                state.wodStatus = .notFinished
                return .none

            case let .view(.updateRounds(rounds)):
                state.dnfRounds = max(0, rounds)
                syncDerivedReps(&state)
                return .none

            case let .view(.updateExtraReps(reps)):
                state.dnfExtraReps = max(0, reps)
                syncDerivedReps(&state)
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
                state.noteState = .editing
                return .none
            }
        }
    }

    // MARK: - Derived reps

    /// Writes the reps the entered score implies, so the athlete states it once
    /// instead of restating it per movement.
    ///
    /// Called only where the athlete expressed a score — never on the flip to
    /// not-finished, which would stamp an untouched card with the steppers' zeroes.
    private func syncDerivedReps(_ state: inout State) {
        syncLadderReps(&state)
        syncRoundReps(&state)
    }

    /// A ladder's rounds shrink, so each movement's total is the sum of the rungs it reached.
    private func syncLadderReps(_ state: inout State) {
        guard state.wodType == .forTime,
              let ladder = state.repScheme, !ladder.isEmpty
        else { return }

        for index in state.result.exercises.indices where state.ladderOwns(exerciseAt: index) {
            let reps = state.wodStatus == .completed
                ? ladder.reduce(0, +)
                : LadderScore.reps(
                    ladder: ladder,
                    movementIndex: index,
                    completedRounds: state.dnfRounds,
                    extraReps: state.dnfExtraReps
                )
            state.result.exercises[index].actualReps = "\(reps)"
        }
    }

    /// A flat block repeats one round, so each movement's total is its own share of
    /// the rounds plus whatever of the partial round reached it.
    ///
    /// The unit travels with the number: after the save the suffix is the only thing
    /// marking calories as calories.
    private func syncRoundReps(_ state: inout State) {
        guard state.roundDrivesReps else { return }
        let sizes = state.roundSizes

        for index in state.result.exercises.indices where state.roundOwns(exerciseAt: index) {
            let total = RoundScore.reps(
                roundSizes: sizes,
                movementIndex: index,
                completedRounds: state.dnfRounds,
                extraReps: state.dnfExtraReps
            )
            state.result.exercises[index].actualReps = state.result.exercises[index].target
                .map { $0.with(count: total).compactString }
        }
    }
}
