//
//  SetInputView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 24/04/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

@ViewAction(for: SetInputFeature.self)
struct SetInputView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<SetInputFeature>

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    scoreSection
                    ForEach(Array(store.exercises.enumerated()), id: \.offset) { exIndex, exercise in
                        exerciseCard(exerciseIndex: exIndex, exercise: exercise)
                    }
                }
                .padding()
            }
            .navigationTitle(store.wodName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Score Section

    @ViewBuilder
    private var scoreSection: some View {
        switch store.wodType {
        case .strength, .olympicWeightlifting:
            EmptyView()
        case .amrap:
            amrapScoreSection
        case .forTime:
            forTimeScoreSection
        case .emom, .tabata:
            EmptyView()
        }
    }

    private var amrapScoreSection: some View {
        GroupBox {
            HStack(spacing: 12) {
                scoreLabel
                amrapRoundsField
                amrapPlusSeparator
                amrapRepsField
            }
        }
        .styledGroupBox()
    }

    private var amrapRoundsField: some View {
        numberField(
            placeholder: String(localized: "Rounds"),
            text: amrapRoundsBinding,
            keyboard: .numberPad
        )
        .frame(maxWidth: .infinity)
    }

    private var amrapPlusSeparator: some View {
        Text("+")
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    private var amrapRepsField: some View {
        numberField(
            placeholder: String(localized: "Reps"),
            text: amrapRepsBinding,
            keyboard: .numberPad
        )
        .frame(maxWidth: .infinity)
    }

    private var forTimeScoreSection: some View {
        GroupBox {
            HStack {
                scoreLabel
                forTimeScoreField
            }
        }
        .styledGroupBox()
    }

    private var forTimeScoreField: some View {
        numberField(
            placeholder: "mm:ss",
            text: $store.scoreText,
            keyboard: .numbersAndPunctuation
        )
    }

    private var scoreLabel: some View {
        Text(String(localized: "Score:"))
            .font(.subheadline.weight(.semibold))
    }

    /// Binding that reads/writes the "rounds" part of scoreText ("6+14" → "6").
    private var amrapRoundsBinding: Binding<String> {
        Binding(
            get: {
                let parts = store.scoreText.split(separator: "+")
                return parts.first.map(String.init) ?? store.scoreText
            },
            set: { rounds in
                let parts = store.scoreText.split(separator: "+")
                let reps = parts.count > 1 ? String(parts[1]).trimmingCharacters(in: .whitespaces) : ""
                store.scoreText = reps.isEmpty ? rounds : "\(rounds)+\(reps)"
            }
        )
    }

    /// Binding that reads/writes the "extra reps" part of scoreText ("6+14" → "14").
    private var amrapRepsBinding: Binding<String> {
        Binding(
            get: {
                let parts = store.scoreText.split(separator: "+")
                return parts.count > 1 ? String(parts[1]).trimmingCharacters(in: .whitespaces) : ""
            },
            set: { reps in
                let parts = store.scoreText.split(separator: "+")
                let rounds = parts.first.map(String.init) ?? ""
                store.scoreText = reps.isEmpty ? rounds : "\(rounds)+\(reps)"
            }
        )
    }

    // MARK: - Exercise Card

    private func exerciseCard(exerciseIndex: Int, exercise: ExerciseLogInput) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                exerciseCardHeader(exercise: exercise)
                if exercise.sets != nil {
                    strengthGrid(exerciseIndex: exerciseIndex, exercise: exercise)
                } else {
                    simpleInput(exerciseIndex: exerciseIndex, exercise: exercise)
                }
            }
        }
        .styledGroupBox()
    }

    // MARK: - Exercise Card Header

    private func exerciseCardHeader(exercise: ExerciseLogInput) -> some View {
        HStack {
            exerciseHeaderName(exercise)
            unmatchedIndicator(exercise)
            Spacer()
            plannedRepsText(exercise)
        }
    }

    private func exerciseHeaderName(_ exercise: ExerciseLogInput) -> some View {
        Text(exercise.displayName)
            .font(.subheadline.weight(.semibold))
    }

    @ViewBuilder
    private func unmatchedIndicator(_ exercise: ExerciseLogInput) -> some View {
        if exercise.isUnmatched {
            Image(systemName: "questionmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.orange)
        }
    }

    @ViewBuilder
    private func plannedRepsText(_ exercise: ExerciseLogInput) -> some View {
        if let reps = exercise.plannedReps {
            Text(String(localized: "Plan: \(reps)"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Simple Input (WOD exercises)

    private func simpleInput(exerciseIndex: Int, exercise: ExerciseLogInput) -> some View {
        HStack(spacing: 8) {
            simpleInputRepsField(exerciseIndex: exerciseIndex, exercise: exercise)
            if needsWeight(for: exercise) {
                simpleInputWeightField(exerciseIndex: exerciseIndex, exercise: exercise)
            }
        }
    }

    private func simpleInputRepsField(exerciseIndex: Int, exercise: ExerciseLogInput) -> some View {
        numberField(
            placeholder: unitPlaceholder(exercise),
            text: Binding(
                get: { store.exercises[exerciseIndex].actualReps ?? "" },
                set: { newText in
                    store.exercises[exerciseIndex].actualReps = newText.isEmpty ? nil : newText
                }
            )
        )
    }

    private func simpleInputWeightField(exerciseIndex: Int, exercise: ExerciseLogInput) -> some View {
        numberField(
            placeholder: "kg",
            text: Binding(
                get: { store.exercises[exerciseIndex].actualWeight.map { "\(Int($0))" } ?? "" },
                set: { newText in
                    store.exercises[exerciseIndex].actualWeight = Double(newText)
                }
            ),
            keyboard: .decimalPad
        )
        .frame(width: 70)
    }

    private func needsWeight(for exercise: ExerciseLogInput) -> Bool {
        if let type = exercise.exerciseType, type.requiresWeight {
            return true
        }
        return exercise.plannedWeight != nil
    }

    // MARK: - Strength Grid (per-set)

    private func strengthGrid(exerciseIndex: Int, exercise: ExerciseLogInput) -> some View {
        let sets = exercise.sets ?? []
        return Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
            strengthGridHeader
            Divider()
            ForEach(Array(sets.enumerated()), id: \.offset) { setIndex, entry in
                strengthGridRow(exerciseIndex: exerciseIndex, setIndex: setIndex, entry: entry)
            }
        }
    }

    private var strengthGridHeader: some View {
        GridRow {
            Text(String(localized: "Set"))
                .frame(width: 30)
            Text(String(localized: "Reps"))
                .frame(maxWidth: .infinity)
            Text("kg")
                .frame(width: 80)
        }
        .font(.caption)
        .foregroundStyle(.tertiary)
    }

    private func strengthGridRow(exerciseIndex: Int, setIndex: Int, entry: SetEntry) -> some View {
        GridRow {
            setIndexCell(setIndex)
            setRepsField(exerciseIndex: exerciseIndex, setIndex: setIndex, entry: entry)
            setWeightField(exerciseIndex: exerciseIndex, setIndex: setIndex, entry: entry)
        }
    }

    private func setIndexCell(_ setIndex: Int) -> some View {
        Text("\(setIndex + 1)")
            .font(.body.monospacedDigit())
            .foregroundStyle(.secondary)
            .frame(width: 30)
    }

    private func setRepsField(exerciseIndex: Int, setIndex: Int, entry: SetEntry) -> some View {
        numberField(
            placeholder: String(localized: "Reps"),
            text: Binding(
                get: {
                    guard let sets = store.exercises[exerciseIndex].sets,
                          setIndex < sets.count else { return "" }
                    return "\(sets[setIndex].reps)"
                },
                set: { newText in
                    store.exercises[exerciseIndex].sets?[setIndex].reps = Int(newText) ?? 0
                }
            ),
            keyboard: .numberPad
        )
    }

    private func setWeightField(exerciseIndex: Int, setIndex: Int, entry: SetEntry) -> some View {
        numberField(
            placeholder: "kg",
            text: Binding(
                get: {
                    guard let sets = store.exercises[exerciseIndex].sets,
                          setIndex < sets.count else { return "" }
                    return sets[setIndex].weight.map { "\(Int($0))" } ?? ""
                },
                set: { newText in
                    store.exercises[exerciseIndex].sets?[setIndex].weight = Double(newText)
                }
            ),
            keyboard: .decimalPad
        )
        .frame(width: 80)
    }

    // MARK: - Number Field Helper

    private func numberField(
        placeholder: String,
        text: Binding<String>,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        TextField(placeholder, text: text)
            .textFieldStyle(.plain)
            .padding(8)
            .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
            .keyboardType(keyboard)
    }

    // MARK: - Unit Placeholder

    private func unitPlaceholder(_ exercise: ExerciseLogInput) -> String {
        switch exercise.target {
        case .reps:     return String(localized: "Reps")
        case .calories: return String(localized: "Calories")
        case .meters:   return String(localized: "Meters")
        case .seconds:  return String(localized: "Seconds")
        case .minutes:  return String(localized: "Minutes")
        case .rounds:   return String(localized: "Rounds")
        case .laps:     return String(localized: "Laps")
        case nil:       return String(localized: "Reps")
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            cancelButton
        }
        ToolbarItem(placement: .confirmationAction) {
            addButton
        }
    }

    private var cancelButton: some View {
        Button {
            send(.cancelTapped)
        } label: {
            Text(String(localized: "Cancel"))
        }
    }

    private var addButton: some View {
        Button {
            send(.addTapped)
        } label: {
            Text(String(localized: "Add"))
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Preview

#Preview("WOD — AMRAP") {
    SetInputView(store: Store(initialState: SetInputFeature.State(
        wodName: "WOD 1",
        scoreText: "",
        scorePlaceholder: "Rounds + reps",
        exercises: [
            ExerciseLogInput(exerciseType: .pullUps, category: .gymnastics, target: .reps(9), plannedReps: "9", actualReps: "9"),
            ExerciseLogInput(exerciseType: .thrusters, category: .olympicLifting, target: .reps(8), plannedReps: "8", plannedWeight: 50, actualWeight: 50, actualReps: "8"),
            ExerciseLogInput(exerciseType: .rowing, category: .cardio, target: .calories(17), plannedReps: "17 cal", actualReps: "17"),
        ],
        wodType: .amrap,
        wodIndex: 0
    )) {
        SetInputFeature()
    })
}

#Preview("Strength — 5x10") {
    SetInputView(store: Store(initialState: SetInputFeature.State(
        wodName: "Strength",
        scoreText: "",
        scorePlaceholder: "Heaviest set (kg)",
        exercises: [
            ExerciseLogInput(
                exerciseType: .benchPress,
                category: .strength,
                target: .reps(10),
                plannedReps: "10-10-10-10-10",
                sets: [
                    SetEntry(reps: 10, weight: 40),
                    SetEntry(reps: 10, weight: 45),
                    SetEntry(reps: 10),
                    SetEntry(reps: 10),
                    SetEntry(reps: 10),
                ]
            ),
        ],
        wodType: .strength,
        wodIndex: 1
    )) {
        SetInputFeature()
    })
}
