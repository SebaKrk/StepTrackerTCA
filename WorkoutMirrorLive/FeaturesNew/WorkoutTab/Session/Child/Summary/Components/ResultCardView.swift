//
//  ResultCardView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 28/07/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

/// One result card driven by its own element store. Renders per phase (empty
/// slot → inline editor → frozen typed result) reading fields via dynamic
/// member, so fine-grained observation fires on every reducer mutation.
@ViewAction(for: WODScoringFeature.self)
struct ResultCardView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<WODScoringFeature>
    let accent: Color
    @Environment(\.summaryPalette) private var theme
    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            phaseContent
            noteRow
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .summaryCard()
    }

    // MARK: - Structure

    private var header: some View {
        ResultCardHeader(
            kind: isStrength ? .strength : .wod,
            chipText: chipTitle,
            name: isStrength ? store.result.exercises.first?.displayName : nil,
            planSub: strengthPlanSub,
            capText: capText,
            status: headerStatus,
            accent: accent
        )
    }

    @ViewBuilder
    private var phaseContent: some View {
        switch store.phase {
        case .empty:
            emptyContent
        case .editing:
            editingContent
        case .entered:
            enteredContent
        }
    }

    // Plan visible above the slot; one primary action per card.
    @ViewBuilder
    private var emptyContent: some View {
        if !isStrength {
            ExerciseList(items: ladderItems(withValues: false), accent: accent)
        }
        if let hint = emptyHint {
            ScoreLine(kind: scoreKind, variant: .empty(hint: hint))
        }
        if !store.isReadOnly {
            emptyActionButton
        }
    }

    private var editingContent: some View {
        InlineResultEditor(store: store, accent: accent)
    }

    // Frozen result; plan ladder stays visible. Tap re-opens editing.
    @ViewBuilder
    private var enteredContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            enteredScoreLine
            if isStrength {
                strengthTable
            } else {
                ExerciseList(items: ladderItems(withValues: true), accent: accent)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !store.isReadOnly { send(.startEditingTapped) }
        }
    }

    private var noteRow: some View {
        NoteRow(
            state: store.isReadOnly && store.noteState != .saved ? .empty : store.noteState,
            text: store.result.note,
            onAdd: { send(.addNoteTapped) },
            onTextChange: { send(.updateNote($0)) },
            onCommit: { send(.commitNote) },
            onEditSaved: { send(.savedNoteTapped) }
        )
        .opacity(store.isReadOnly && store.noteState != .saved ? 0 : 1)
        .frame(height: store.isReadOnly && store.noteState != .saved ? 0 : nil)
    }

    // MARK: - Implementation

    private var emptyActionButton: some View {
        CardActionButton(title: emptyActionTitle) {
            if isConfirmationOnly {
                send(.doneTapped)
            } else {
                send(.startEditingTapped)
            }
        }
    }

    @ViewBuilder
    private var enteredScoreLine: some View {
        switch store.result.scoreResult {
        case let .forTime(time):
            ScoreLine(
                kind: String(localized: "Wynik · For Time"),
                variant: .filled(
                    value: timeText(Int(time)),
                    detail: store.capMinutes.map { String(localized: "limit \($0):00") },
                    isPR: false
                )
            )

        case let .amrap(rounds, extraReps) where store.isDNF:
            ScoreLine(
                kind: String(localized: "Wynik · Time cap"),
                variant: .dnf(
                    value: store.capMinutes.map { "\($0):00" } ?? "—",
                    detail: String(localized: "· \(rounds) rund + \(extraReps) reps")
                )
            )

        case let .amrap(rounds, extraReps):
            ScoreLine(
                kind: String(localized: "Wynik · AMRAP"),
                variant: .filled(
                    value: String(localized: "\(rounds) rund + \(extraReps) reps"),
                    detail: nil,
                    isPR: false
                )
            )

        case .forLoad:
            if let top = heaviestSet {
                ScoreLine(
                    kind: String(localized: "Najcięższa seria"),
                    variant: .filled(
                        value: "\(formatWeight(top.weight)) kg",
                        detail: "× \(top.reps)",
                        isPR: store.result.exercises.first?.isPR ?? false
                    )
                )
            }

        case let .custom(text):
            ScoreLine(kind: scoreKind, variant: .filled(value: text, detail: nil, isPR: false))

        case .completed, .timeCap, .forReps:
            // EMOM/Tabata: the ✓ pill in the header is the whole story.
            EmptyView()
        }
    }

    @ViewBuilder
    private var strengthTable: some View {
        if let exercise = store.result.exercises.first, let sets = exercise.sets {
            SetTable(
                sets: sets,
                isEditing: false,
                accent: accent,
                isPR: exercise.isPR,
                onReps: { _, _ in },
                onWeight: { _, _ in }
            )
        }
    }

    // MARK: - Ladder mapping

    /// Builds ladder rows from the exercises; with values, actuals show
    /// weight/✓, and a DNF card gets the amber limit separator with muted
    /// rows below the cutoff.
    private func ladderItems(withValues: Bool) -> [ExerciseList.Item] {
        let exercises = store.result.exercises
        var items: [ExerciseList.Item] = []
        let cutoff = withValues && store.isDNF ? dnfCutoffIndex : exercises.count

        for (index, exercise) in exercises.enumerated() {
            if index == cutoff {
                items.append(.limit(text: String(localized: "limit \(store.capMinutes ?? 0):00")))
            }
            let isMuted = index >= cutoff
            items.append(
                .exercise(
                    .init(
                        repPrefix: repPrefix(exercise.plannedReps),
                        name: exercise.displayName,
                        scaling: exercise.plannedWeight.map { "\(formatWeight($0)) kg" },
                        actual: withValues && !isMuted ? actual(for: exercise) : .none,
                        isMuted: withValues ? isMuted : false
                    )
                )
            )
        }
        return items
    }

    /// Last exercise with any entered data marks the DNF cutoff.
    private var dnfCutoffIndex: Int {
        let lastWithData = store.result.exercises.lastIndex { exercise in
            exercise.actualWeight != nil || exercise.actualReps != nil
        }
        return lastWithData.map { $0 + 1 } ?? store.result.exercises.count
    }

    private func actual(for exercise: ExerciseLogInput) -> ExerciseList.Actual {
        if let weight = exercise.actualWeight {
            return .weight("\(formatWeight(weight)) kg", rx: weight == exercise.plannedWeight)
        }
        if let actualReps = exercise.actualReps {
            // "12" done of a planned "30" → partial row (DNF cutoff point).
            if let done = Int(actualReps),
               let planned = exercise.plannedReps.flatMap(Int.init),
               done < planned {
                return .partial(done: done, total: planned)
            }
            return .done
        }
        return .none
    }

    private func repPrefix(_ plannedReps: String?) -> String? {
        guard let plannedReps, !plannedReps.isEmpty else { return nil }
        return Int(plannedReps) != nil ? "\(plannedReps)×" : plannedReps
    }

    // MARK: - Helpers

    private var chipTitle: String {
        isStrength ? String(localized: "Strength") : store.result.name
    }

    private var strengthPlanSub: String? {
        guard isStrength, let plannedReps = store.result.exercises.first?.plannedReps else { return nil }
        return String(localized: "Plan: \(plannedReps)")
    }

    private var capText: String? {
        guard let capMinutes = store.capMinutes else { return nil }
        return store.wodType == .amrap
            ? String(localized: "AMRAP \(capMinutes) min")
            : String(localized: "\(capMinutes) min cap")
    }

    /// Status per the entry matrix: For Time + cap → always-visible segment;
    /// For Time without cap / EMOM / Tabata → ✓ pill once entered; others → none.
    private var headerStatus: StatusControl.Mode? {
        switch store.wodType {
        case .forTime where store.capMinutes != nil:
            if store.isReadOnly {
                return store.phase == .entered ? .pill(completed: !store.isDNF) : nil
            }
            return .segment(status: store.wodStatus, onChange: { send(.setStatus($0)) })
        case .forTime, .emom, .tabata:
            return store.phase == .entered ? .pill(completed: true) : nil
        case .strength, .olympicWeightlifting, .amrap:
            return nil
        }
    }

    private var isStrength: Bool {
        store.wodType == .strength || store.wodType == .olympicWeightlifting
    }

    private var isConfirmationOnly: Bool {
        store.wodType == .emom || store.wodType == .tabata
    }

    private var scoreKind: String {
        switch store.wodType {
        case .strength, .olympicWeightlifting: String(localized: "Serie")
        case .amrap: String(localized: "Wynik · AMRAP")
        case .forTime: String(localized: "Wynik · For Time")
        case .emom, .tabata: String(localized: "Wynik")
        }
    }

    private var emptyHint: String? {
        switch store.wodType {
        case .strength, .olympicWeightlifting:
            let count = store.result.exercises.first?.sets?.count ?? 0
            return String(localized: "\(count) serii · powtórzenia + kg")
        case .forTime:
            return "mm:ss"
        case .amrap:
            return String(localized: "rundy + powtórzenia")
        case .emom, .tabata:
            return nil
        }
    }

    private var emptyActionTitle: String {
        switch store.wodType {
        case .strength, .olympicWeightlifting: String(localized: "Wpisz serie")
        case .emom, .tabata: String(localized: "Gotowe")
        default: String(localized: "Wpisz wyniki")
        }
    }

    private var heaviestSet: (weight: Double, reps: Int)? {
        let sets = store.result.exercises.flatMap { $0.sets ?? [] }
        guard let top = sets.filter({ $0.weight != nil }).max(by: { ($0.weight ?? 0) < ($1.weight ?? 0) }),
              let weight = top.weight
        else { return nil }
        return (weight, top.reps)
    }

    private func timeText(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    private func formatWeight(_ weight: Double) -> String {
        weight.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(weight))
            : String(format: "%.1f", weight)
    }
}

// MARK: - Previews (karty typów T1–T7 z makiety)

private func previewCard(_ state: WODScoringFeature.State) -> some View {
    ResultCardView(
        store: Store(initialState: state) { WODScoringFeature() },
        accent: SummaryTheme.mint
    )
}

#Preview("T1–T3 · For Time (cap ukończony / DNF / bez capa)") {
    ScrollView {
        VStack(spacing: 12) {
            previewCard(
                WODScoringFeature.State(
                    wodIndex: 0,
                    result: WorkoutSessionResult(
                        name: "WOD",
                        description: "FOR TIME",
                        scoreResult: .forTime(time: 540),
                        exercises: [
                            ExerciseLogInput(exerciseType: .doubleUnders, category: .cardio, plannedReps: "50", actualReps: "50"),
                            ExerciseLogInput(exerciseType: .shoulderPress, category: .strength, plannedReps: "5", plannedWeight: 40, actualWeight: 40),
                        ]
                    ),
                    wodType: .forTime,
                    capMinutes: 11
                )
            )
            previewCard(
                WODScoringFeature.State(
                    wodIndex: 1,
                    result: WorkoutSessionResult(
                        name: "WOD",
                        description: "FOR TIME",
                        scoreResult: .amrap(rounds: 4, extraReps: 12),
                        exercises: [
                            ExerciseLogInput(exerciseType: .thrusters, category: .olympicLifting, plannedReps: "30", plannedWeight: 40, actualReps: "12"),
                            ExerciseLogInput(exerciseType: .burpees, category: .mixed, plannedReps: "35"),
                        ]
                    ),
                    wodType: .forTime,
                    capMinutes: 11
                )
            )
            previewCard(
                WODScoringFeature.State(
                    wodIndex: 2,
                    result: WorkoutSessionResult(
                        name: "WOD",
                        description: "FOR TIME",
                        scoreResult: .forTime(time: 872),
                        exercises: [
                            ExerciseLogInput(exerciseType: .thrusters, category: .olympicLifting, plannedReps: "21-15-9", actualReps: "21-15-9"),
                        ]
                    ),
                    wodType: .forTime
                )
            )
        }
        .padding(16)
    }
    .background(SummaryTheme.background)
}

#Preview("T4–T7 · AMRAP / EMOM / Tabata / Strength") {
    ScrollView {
        VStack(spacing: 12) {
            previewCard(
                WODScoringFeature.State(
                    wodIndex: 0,
                    result: WorkoutSessionResult(
                        name: "WOD",
                        description: "AMRAP 20",
                        scoreResult: .amrap(rounds: 6, extraReps: 14),
                        exercises: [
                            ExerciseLogInput(exerciseType: .pullUps, category: .gymnastics, plannedReps: "9", actualReps: "9"),
                            ExerciseLogInput(exerciseType: .thrusters, category: .olympicLifting, plannedReps: "8", plannedWeight: 50, actualWeight: 50),
                        ]
                    ),
                    wodType: .amrap,
                    capMinutes: 20
                )
            )
            previewCard({
                var card = WODScoringFeature.State(
                    wodIndex: 1,
                    result: WorkoutSessionResult(
                        name: "EMOM 12",
                        description: "EMOM",
                        scoreResult: .completed,
                        note: "od 9. minuty row po 10 cal.",
                        exercises: [
                            ExerciseLogInput(exerciseType: .rowing, category: .cardio, plannedReps: "12 cal", actualReps: "12"),
                            ExerciseLogInput(exerciseType: .burpees, category: .mixed, plannedReps: "10", actualReps: "10"),
                        ]
                    ),
                    wodType: .emom
                )
                card.phase = .entered
                return card
            }())
            previewCard({
                var card = WODScoringFeature.State(
                    wodIndex: 2,
                    result: WorkoutSessionResult(
                        name: "Tabata",
                        description: "8×20s/10s",
                        scoreResult: .completed,
                        exercises: [
                            ExerciseLogInput(exerciseType: .airSquat, category: .gymnastics, plannedReps: "8x20s", actualReps: "done"),
                        ]
                    ),
                    wodType: .tabata
                )
                card.phase = .entered
                return card
            }())
            previewCard(
                WODScoringFeature.State(
                    wodIndex: 3,
                    result: WorkoutSessionResult(
                        name: "Strength",
                        description: "5×2 Back Squat",
                        scoreResult: .forLoad(weight: 150),
                        exercises: [
                            ExerciseLogInput(
                                exerciseType: .backSquat,
                                category: .strength,
                                plannedReps: "2-2-2",
                                sets: [
                                    SetEntry(reps: 2, weight: 145),
                                    SetEntry(reps: 2, weight: 150),
                                    SetEntry(reps: 2, weight: 147),
                                ],
                                isPR: true
                            ),
                        ]
                    ),
                    wodType: .strength
                )
            )
        }
        .padding(16)
    }
    .background(SummaryTheme.background)
}

#Preview("Fazy · pusty / edycja") {
    ScrollView {
        VStack(spacing: 12) {
            previewCard(
                WODScoringFeature.State(
                    wodIndex: 0,
                    result: WorkoutSessionResult(
                        name: "WOD 1",
                        description: "FOR TIME",
                        exercises: [
                            ExerciseLogInput(exerciseType: .doubleUnders, category: .cardio, plannedReps: "50"),
                            ExerciseLogInput(exerciseType: .thrusters, category: .olympicLifting, plannedReps: "10", plannedWeight: 40),
                        ]
                    ),
                    wodType: .forTime,
                    capMinutes: 12
                )
            )
            previewCard(
                WODScoringFeature.State(
                    wodIndex: 1,
                    result: WorkoutSessionResult(
                        name: "Strength",
                        description: "5×2 Back Squat",
                        exercises: [
                            ExerciseLogInput(
                                exerciseType: .backSquat,
                                category: .strength,
                                plannedReps: "2-2-2-2-2",
                                sets: (0..<5).map { _ in SetEntry(reps: 2) }
                            ),
                        ]
                    ),
                    wodType: .strength
                )
            )
            previewCard({
                var card = WODScoringFeature.State(
                    wodIndex: 2,
                    result: WorkoutSessionResult(
                        name: "WOD 2",
                        description: "FOR TIME",
                        exercises: [
                            ExerciseLogInput(exerciseType: .burpees, category: .mixed, plannedReps: "35"),
                        ]
                    ),
                    wodType: .forTime,
                    capMinutes: 11
                )
                card.phase = .editing
                card.draftMinutes = 9
                return card
            }())
        }
        .padding(16)
    }
    .background(SummaryTheme.background)
}
