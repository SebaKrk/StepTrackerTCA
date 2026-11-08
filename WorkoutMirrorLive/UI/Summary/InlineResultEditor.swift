//
//  InlineResultEditor.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 27/07/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

/// Card editing mode — everything inline, no sheets. Driven by the card's own
/// store: reads fields via dynamic member, sends actions directly. The field
/// set follows the entry matrix: For Time → mm:ss wheels (+ soft cap hint,
/// rule R-a); AMRAP / DNF → rounds+reps tiles; Strength → editable set table;
/// EMOM/Tabata → per-exercise fields only. "Gotowe" freezes the typed result.
@ViewAction(for: WODScoringFeature.self)
struct InlineResultEditor: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<WODScoringFeature>
    let accent: Color
    @Environment(\.summaryPalette) private var theme

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            scoreEntrySection
            capHint
            totalRepsHint
            exerciseFields
            doneButton
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Structure

    @ViewBuilder
    private var scoreEntrySection: some View {
        switch store.scoreEntry {
        case .time:
            forTimeEntry
        case .roundsAndReps:
            roundsAndRepsEntry
        case .sets, .totalPerMovement, .confirmation:
            // Sets derive their score from the heaviest one, a per-movement total is
            // summed from the rows below, and a confirmation block asks nothing.
            EmptyView()
        }
    }

    @ViewBuilder
    private var exerciseFields: some View {
        // Read once: the set is rebuilt on every access, and the rows below are a loop.
        let derivedReps = store.derivedRepsIndices
        ForEach(Array(store.result.exercises.enumerated()), id: \.element.id) { index, exercise in
            if let sets = exercise.sets, !sets.isEmpty {
                setBasedExercise(index: index, exercise: exercise, sets: sets)
            } else {
                simpleExerciseRow(
                    index: index,
                    exercise: exercise,
                    showsDerivedReps: derivedReps.contains(index)
                )
            }
        }
    }

    // The plan holds an interval here, not a rep count, so these fields start empty
    // and the athlete has to be told what goes in them.
    @ViewBuilder
    private var totalRepsHint: some View {
        if store.scoreEntry == .totalPerMovement {
            scoreEntryLabel(String(localized: "Enter total reps / calories", bundle: .main))
        }
    }

    private var doneButton: some View {
        CardActionButton(title: String(localized: "Gotowe", bundle: .main)) {
            send(.doneTapped)
        }
    }

    // MARK: - Implementation

    private var forTimeEntry: some View {
        VStack(alignment: .leading, spacing: 8) {
            scoreEntryLabel(store.wodType.scoreLabel)
            TimePickerField(
                minutes: store.draftMinutes,
                seconds: store.draftSeconds,
                maxMinutes: store.capMinutes ?? 99,
                onMinutes: { send(.updateDraftMinutes($0)) },
                onSeconds: { send(.updateDraftSeconds($0)) }
            )
        }
    }

    private var roundsAndRepsEntry: some View {
        RoundsAndRepsFields(
            title: roundsAndRepsTitle,
            rounds: store.dnfRounds,
            extraReps: store.dnfExtraReps,
            onRounds: { send(.updateRounds($0)) },
            onExtraReps: { send(.updateExtraReps($0)) }
        )
    }

    private var roundsAndRepsTitle: String {
        store.capturesUnfinished
            ? String(localized: "How far did you get before the cap?", bundle: .main)
            : String(localized: "Score", bundle: .main)
    }

    private func scoreEntryLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .tracking(0.8)
            .textCase(.uppercase)
            .foregroundStyle(theme.inkSecondary)
    }

    /// Rule R-a: draft time over the cap — suggest DNF, never block.
    @ViewBuilder
    private var capHint: some View {
        if store.exceedsCap, let capMinutes = store.capMinutes {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 11))
                Text(String(localized: "Time exceeds the \(capMinutes):00 cap", bundle: .main))
                    .font(.system(size: 12))
                markAsNotFinishedButton
            }
            .foregroundStyle(.orange)
        }
    }

    private var markAsNotFinishedButton: some View {
        Button {
            send(.markNotFinishedFromHint)
        } label: {
            Text(String(localized: "Mark as Not finished?", bundle: .main))
                .font(.system(size: 12, weight: .bold))
                .underline()
        }
        .buttonStyle(.plain)
    }

    private func setBasedExercise(index: Int, exercise: ExerciseLogInput, sets: [SetEntry]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            exerciseName(exercise)
            SetTable(
                sets: sets,
                isEditing: true,
                accent: accent,
                isPR: exercise.isPR,
                // Mobility sets are reps-only — stretching never loads a bar.
                showsWeight: store.wodType.takesWeight,
                onReps: { setIndex, text in send(.updateSetReps(exerciseIndex: index, setIndex: setIndex, text: text)) },
                onWeight: { setIndex, text in send(.updateSetWeight(exerciseIndex: index, setIndex: setIndex, text: text)) }
            )
        }
    }

    private func simpleExerciseRow(
        index: Int,
        exercise: ExerciseLogInput,
        showsDerivedReps: Bool
    ) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                exerciseName(exercise)
                planLabel(exercise)
            }
            Spacer(minLength: 8)
            // Reps that follow from the score above are shown, not asked for.
            if showsDerivedReps {
                derivedRepsLabel(exercise)
            } else {
                actualValueField(index: index, exercise: exercise)
            }
            // Reserve the weight lane only when some exercise in this WOD loads a
            // bar — a weightless WOD (EMOM/Tabata) right-aligns its values instead
            // of leaving a blank kg gap on the right.
            if sectionTakesWeight {
                weightColumn(index: index, exercise: exercise)
            }
        }
    }

    /// Any exercise in this card loads a bar — decides whether the whole section
    /// reserves the weight lane (so reps stay aligned across mixed rows).
    private var sectionTakesWeight: Bool {
        store.result.exercises.contains { takesWeight($0) }
    }

    /// Within a weighted section, bodyweight rows show a blank slot instead of
    /// collapsing it, so the reps field lines up under the weighted rows'.
    @ViewBuilder
    private func weightColumn(index: Int, exercise: ExerciseLogInput) -> some View {
        if takesWeight(exercise) {
            weightField(index: index, exercise: exercise)
        } else {
            Color.clear.frame(width: valueColumnWidth, height: 0)
        }
    }

    /// Bodyweight moves (pull-ups, burpees…) get no weight field — only lifts
    /// that load a bar. Falls back to the plan's weight when the type is unknown.
    private func takesWeight(_ exercise: ExerciseLogInput) -> Bool {
        exercise.requiresWeight || (exercise.exerciseType == nil && exercise.plannedWeight != nil)
    }

    /// Clean numeric input + the target's unit as a trailing label (cal / m / s;
    /// reps show no unit). Storage keeps the `compactString` format so history and
    /// analytics stay unaffected.
    private func actualValueField(index: Int, exercise: ExerciseLogInput) -> some View {
        fieldWithUnit(
            unit: ExerciseTarget.unitLabel(for: exercise.target),
            text: EnteredValue.numericPrefix(exercise.actualReps)
        ) { typed in
            repsTyped(typed, index: index, target: exercise.target)
        }
    }

    private func repsTyped(_ typed: String, index: Int, target: ExerciseTarget?) {
        send(.updateExerciseReps(
            exerciseIndex: index,
            text: target?.stored(entered: typed) ?? typed
        ))
    }

    /// Reps the ladder implies — same lane as the editable field, so the rows stay aligned.
    private func derivedRepsLabel(_ exercise: ExerciseLogInput) -> some View {
        HStack(spacing: 4) {
            Text(EnteredValue.numericPrefix(exercise.actualReps))
                .font(.system(size: 16, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(theme.ink)
                .frame(width: 58, alignment: .trailing)
            Text(ExerciseTarget.unitLabel(for: exercise.target))
                .font(.system(size: 12))
                .foregroundStyle(theme.inkTertiary)
                .frame(width: unitColumnWidth, alignment: .leading)
        }
    }

    private func weightField(index: Int, exercise: ExerciseLogInput) -> some View {
        fieldWithUnit(
            unit: "kg",
            text: exercise.actualWeight.map(\.roundedWeightText) ?? ""
        ) { send(.updateExerciseWeight(exerciseIndex: index, text: $0)) }
    }

    /// Numeric input with the unit as a trailing label (10 · reps, 20 · cal,
    /// 30 · kg) — the value stays a clean editable number.
    private func fieldWithUnit(
        unit: String,
        text: String,
        onChange: @escaping (String) -> Void
    ) -> some View {
        HStack(spacing: 4) {
            numericField(placeholder: "0", text: text, onChange: onChange)
            Text(unit)
                .font(.system(size: 12))
                .foregroundStyle(theme.inkTertiary)
                .frame(width: unitColumnWidth, alignment: .leading)
        }
    }

    /// Fixed numeric field (58) + gap (4) + unit label — reps/kg/cal columns
    /// share one width so every value field lines up in the same vertical lane.
    private var unitColumnWidth: CGFloat { 32 }
    private var valueColumnWidth: CGFloat { 58 + 4 + unitColumnWidth }

    private func exerciseName(_ exercise: ExerciseLogInput) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(exercise.displayName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.ink)
            if let caption = exercise.equipmentCaption {
                equipmentLabel(caption, symbol: exercise.equipmentSymbol)
            }
        }
    }

    private func equipmentLabel(_ title: String, symbol: String) -> some View {
        Label(title, systemImage: symbol)
            .font(.system(size: 11))
            .foregroundStyle(theme.inkTertiary)
    }

    @ViewBuilder
    private func planLabel(_ exercise: ExerciseLogInput) -> some View {
        if let plannedReps = exercise.plannedReps {
            Text(String(localized: "Plan: \(prescription(exercise, total: plannedReps))", bundle: .main))
                .font(.system(size: 11))
                .foregroundStyle(theme.inkTertiary)
        }
    }

    /// The board's own wording behind the prefilled total: "5 × 10x" says where the
    /// number beside it came from, which a bare "50x" leaves the athlete to guess.
    private func prescription(_ exercise: ExerciseLogInput, total: String) -> String {
        guard let rounds = store.rounds, rounds > 1,
              exercise.sets == nil,
              let target = exercise.target
        else { return total }
        return "\(rounds) × \(target.compactString)"
    }

    private func numericField(
        placeholder: String,
        text: String,
        onChange: @escaping (String) -> Void
    ) -> some View {
        TextField(placeholder, text: Binding(get: { text }, set: onChange))
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.center)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(theme.ink)
            .frame(width: 58)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.06), in: .rect(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(theme.stroke, lineWidth: 1)
            )
    }
}

// MARK: - Previews

private func previewEditor(_ state: WODScoringFeature.State) -> some View {
    InlineResultEditor(
        store: Store(initialState: state) { WODScoringFeature() },
        accent: SummaryTheme.mint
    )
}

#Preview("Edycja — For Time z hintem R-a") {
    VStack {
        previewEditor({
            var card = WODScoringFeature.State(
                wodIndex: 0,
                result: WorkoutSessionResult(
                    name: "WOD 1",
                    description: "FOR TIME: 21-15-9 Thrusters + Burpees",
                    exercises: [
                        ExerciseLogInput(exerciseType: .thrusters, category: .olympicLifting, plannedReps: "21-15-9", plannedWeight: 43),
                        ExerciseLogInput(exerciseType: .burpees, category: .mixed, plannedReps: "21-15-9"),
                    ]
                ),
                wodType: .forTime,
                capMinutes: 11
            )
            card.phase = .editing
            card.draftMinutes = 11
            card.draftSeconds = 30
            return card
        }())
    }
    .summaryCard()
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SummaryTheme.background)
}

#Preview("Edycja — AMRAP i Strength") {
    ScrollView {
        VStack(spacing: 16) {
            VStack {
                previewEditor({
                    var card = WODScoringFeature.State(
                        wodIndex: 0,
                        result: WorkoutSessionResult(
                            name: "WOD",
                            description: "AMRAP 20'",
                            exercises: [
                                ExerciseLogInput(exerciseType: .pullUps, category: .gymnastics, plannedReps: "9"),
                            ]
                        ),
                        wodType: .amrap
                    )
                    card.phase = .editing
                    card.dnfRounds = 6
                    card.dnfExtraReps = 14
                    return card
                }())
            }
            .summaryCard()

            VStack {
                previewEditor({
                    var card = WODScoringFeature.State(
                        wodIndex: 1,
                        result: WorkoutSessionResult(
                            name: "Back Squat",
                            description: "5×2",
                            exercises: [
                                ExerciseLogInput(
                                    exerciseType: .backSquat,
                                    category: .strength,
                                    plannedReps: "2-2-2",
                                    sets: [
                                        SetEntry(reps: 2, weight: 145),
                                        SetEntry(reps: 2, weight: 150),
                                        SetEntry(reps: 0, weight: nil),
                                    ]
                                ),
                            ]
                        ),
                        wodType: .strength
                    )
                    card.phase = .editing
                    return card
                }())
            }
            .summaryCard()
        }
        .padding(16)
    }
    .background(SummaryTheme.background)
}
