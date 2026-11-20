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
        if let fitnessRun = store.fitnessRun {
            fitnessRunFields(fitnessRun)
        } else {
            standardExerciseFields
        }
    }

    private func fitnessRunFields(_ fitnessRun: FitnessRunPlan) -> some View {
        // Read once: both are rebuilt on every access, and the rows below are a loop.
        let changed = store.changedExerciseIndices
        let runRowIndex = store.runRowIndex
        let firstStation = (runRowIndex ?? -1) + 1
        let isUnfinished = store.capturesUnfinished
        let interrupted = store.interruptedExerciseIndex
        return VStack(alignment: .leading, spacing: 0) {
            if isUnfinished {
                stationsDoneLabel(done: store.dnfRounds, of: store.stationCount)
            } else {
                asPlannedLabel(isAsPlanned: changed.isEmpty)
            }
            ForEach(Array(store.result.exercises.enumerated()), id: \.element.id) { index, exercise in
                let stationNumber = index == runRowIndex ? nil : index - firstStation + 1
                if let interrupted, index == interrupted {
                    interruptedStationRow(exercise: exercise, stationNumber: stationNumber)
                } else if let interrupted, index > interrupted {
                    skippedStationRow(exercise: exercise, stationNumber: stationNumber)
                } else {
                    fitnessRunRow(
                        index: index,
                        exercise: exercise,
                        stationNumber: stationNumber,
                        value: index == runRowIndex
                            ? runSummary(exercise, fitnessRun: fitnessRun)
                            : enteredSummary(exercise),
                        isChanged: !isUnfinished && changed.contains(index)
                    )
                }
            }
            tapToChangeHint
        }
        .animation(.default, value: store.editedExerciseIndex)
        .animation(.default, value: changed)
        .animation(.default, value: interrupted)
    }

    @ViewBuilder
    private var standardExerciseFields: some View {
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
                maxMinutes: store.maxDraftMinutes,
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
            onExtraReps: { send(.updateExtraReps($0)) },
            roundsLabel: store.fitnessRun == nil
                ? String(localized: "Completed rounds", bundle: .main)
                : String(localized: "Completed stations", bundle: .main),
            extraRepsLabel: store.openLadder == nil
                ? String(localized: "Reps in round", bundle: .main)
                : String(localized: "Reps in round \(store.dnfRounds + 1)", bundle: .main),
            showsExtraReps: store.fitnessRun == nil
        )
    }

    private var roundsAndRepsTitle: String {
        if store.fitnessRun != nil {
            return String(localized: "How many stations did you finish?", bundle: .main)
        }
        return store.capturesUnfinished
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

    // MARK: - Fitness run

    private func fitnessRunRow(
        index: Int,
        exercise: ExerciseLogInput,
        stationNumber: Int?,
        value: String,
        isChanged: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                send(.exerciseRowTapped(index))
            } label: {
                fitnessRunRowLabel(exercise: exercise, stationNumber: stationNumber, value: value, isChanged: isChanged)
            }
            .buttonStyle(.plain)
            if store.editedExerciseIndex == index {
                fitnessRunRowFields(index: index, exercise: exercise, isChanged: isChanged)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 9)
        .overlay(alignment: .bottom) {
            Rectangle().fill(theme.stroke).frame(height: 1)
        }
    }

    private func fitnessRunRowLabel(
        exercise: ExerciseLogInput,
        stationNumber: Int?,
        value: String,
        isChanged: Bool
    ) -> some View {
        HStack(spacing: 10) {
            fitnessRunRowMarker(stationNumber)
            Text(exercise.displayName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(theme.ink)
            Spacer(minLength: 8)
            if isChanged {
                changedTag
            }
            Text(value)
                .font(.system(size: 13))
                .monospacedDigit()
                .foregroundStyle(theme.inkTertiary)
        }
        .contentShape(.rect)
    }

    @ViewBuilder
    private func fitnessRunRowMarker(_ stationNumber: Int?) -> some View {
        if let stationNumber {
            Text("\(stationNumber)")
                .font(.system(size: 12, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(theme.inkTertiary)
                .frame(width: 18, alignment: .leading)
        } else {
            Color.clear.frame(width: 18, height: 1)
        }
    }

    private func fitnessRunRowFields(index: Int, exercise: ExerciseLogInput, isChanged: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                actualValueField(index: index, exercise: exercise)
                if takesWeight(exercise) {
                    weightField(index: index, exercise: exercise)
                }
            }
            if isChanged {
                planLabel(exercise)
            }
        }
        .padding(.leading, 28)
    }

    /// The station the athlete stopped on: the one row that asks how much of it was done.
    private func interruptedStationRow(exercise: ExerciseLogInput, stationNumber: Int?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                fitnessRunRowMarker(stationNumber)
                Text(exercise.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.ink)
                Spacer(minLength: 8)
                interruptedTag
            }
            HStack(spacing: 8) {
                numericField(
                    placeholder: "0",
                    text: store.dnfExtraReps > 0 ? "\(store.dnfExtraReps)" : ""
                ) { typed in
                    send(.updateExtraReps(Int(typed) ?? 0))
                }
                Text(String(localized: "of \(plannedSummary(exercise))", bundle: .main))
                    .font(.system(size: 12))
                    .foregroundStyle(theme.inkTertiary)
            }
            .padding(.leading, 28)
        }
        .padding(.vertical, 9)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.orange.opacity(0.6)).frame(height: 1)
        }
    }

    /// A station the athlete never reached.
    private func skippedStationRow(exercise: ExerciseLogInput, stationNumber: Int?) -> some View {
        HStack(spacing: 10) {
            fitnessRunRowMarker(stationNumber)
            Text(exercise.displayName)
                .font(.system(size: 14, weight: .semibold))
            Spacer(minLength: 8)
            Text(verbatim: "—")
                .font(.system(size: 13))
        }
        .foregroundStyle(theme.inkTertiary)
        .opacity(0.6)
        .padding(.vertical, 9)
        .overlay(alignment: .bottom) {
            Rectangle().fill(theme.stroke).frame(height: 1)
        }
    }

    /// The run as the board counts it, "6 × 1000 m", while the distance is still whole runs.
    private func runSummary(_ exercise: ExerciseLogInput, fitnessRun: FitnessRunPlan) -> String {
        guard fitnessRun.runMeters > 0,
              let meters = Int(EnteredValue.numericPrefix(exercise.actualReps)),
              meters % fitnessRun.runMeters == 0
        else { return enteredSummary(exercise) }
        return "\(meters / fitnessRun.runMeters) × \(fitnessRun.runMeters) m"
    }

    /// The plan of a row in the board's own shorthand: "200m · 24 kg".
    private func plannedSummary(_ exercise: ExerciseLogInput) -> String {
        let weight = exercise.plannedWeight.map { "\($0.roundedWeightText) kg" }
        return [exercise.plannedReps, weight].compactMap { $0 }.joined(separator: " · ")
    }

    private func stationsDoneLabel(done: Int, of total: Int) -> some View {
        Text(String(localized: "\(done) of \(total) stations", bundle: .main))
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.orange)
            .padding(.bottom, 4)
    }

    private var interruptedTag: some View {
        Text(String(localized: "interrupted", bundle: .main))
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.orange)
    }

    /// What the row holds right now, in the board's own shorthand: "50m · 152 kg".
    private func enteredSummary(_ exercise: ExerciseLogInput) -> String {
        let weight = exercise.actualWeight.map { "\($0.roundedWeightText) kg" }
        return [exercise.actualReps, weight].compactMap { $0 }.joined(separator: " · ")
    }

    private func asPlannedLabel(isAsPlanned: Bool) -> some View {
        Label(
            isAsPlanned
                ? String(localized: "As planned", bundle: .main)
                : String(localized: "Changed from the plan", bundle: .main),
            systemImage: isAsPlanned ? "checkmark.circle.fill" : "pencil.circle.fill"
        )
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(isAsPlanned ? Color.green : Color.orange)
        .padding(.bottom, 4)
    }

    private var changedTag: some View {
        Text(String(localized: "changed", bundle: .main))
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.orange)
    }

    private var tapToChangeHint: some View {
        Text(String(localized: "Tap a row to change it", bundle: .main))
            .font(.system(size: 11))
            .foregroundStyle(theme.inkTertiary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 8)
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
                ladderShareLabel(index: index)
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

    /// Where an open ladder's number came from: "36 + 9 from round 9".
    @ViewBuilder
    private func ladderShareLabel(index: Int) -> some View {
        if let share = store.openLadderShares[index] {
            Text(
                share.partial > 0
                    ? String(
                        localized: "\(share.whole) + \(share.partial) from round \(store.dnfRounds + 1)",
                        bundle: .main
                    )
                    : String(localized: "\(share.whole) from whole rounds", bundle: .main)
            )
            .font(.system(size: 11))
            .foregroundStyle(theme.inkTertiary)
            .contentTransition(.numericText())
            .animation(.default, value: share)
        }
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
