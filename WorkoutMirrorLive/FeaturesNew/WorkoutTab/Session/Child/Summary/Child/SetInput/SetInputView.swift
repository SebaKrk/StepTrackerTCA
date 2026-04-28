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
                    ForEach(Array(store.exercises.enumerated()), id: \.offset) { exIndex, exercise in
                        exerciseCard(exerciseIndex: exIndex, exercise: exercise)
                    }
                }
                .padding()
            }
            .navigationTitle(store.wodName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                cancelToolbarButton
                addToolbarButton
            }
        }
        .presentationDetents([.medium, .large])
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
            Text(exercise.exerciseType?.displayName ?? exercise.unmatchedName ?? String(localized: "Unknown"))
                .font(.subheadline.weight(.semibold))
            Spacer()
            if let reps = exercise.plannedReps {
                Text(String(localized: "Plan: \(reps)"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Simple Input (WOD exercises)

    private func simpleInput(exerciseIndex: Int, exercise: ExerciseLogInput) -> some View {
        HStack(spacing: 8) {
            TextField(unitPlaceholder(exercise), text: Binding(
                get: { exercise.actualReps ?? "" },
                set: { send(.updateExerciseReps(exerciseIndex: exerciseIndex, $0)) }
            ))
            .textFieldStyle(.plain)
            .padding(8)
            .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
            .keyboardType(.default)

            let needsWeight: Bool = {
                guard let category = exercise.category else { return exercise.plannedWeight != nil }
                switch category {
                case .strength, .olympicLifting:
                    return true
                case .gymnastics, .cardio, .mixed:
                    return exercise.plannedWeight != nil
                }
            }()
            if needsWeight {
                TextField("kg", text: Binding(
                    get: { exercise.actualWeight.map { "\(Int($0))" } ?? "" },
                    set: { send(.updateExerciseWeight(exerciseIndex: exerciseIndex, $0)) }
                ))
                .textFieldStyle(.plain)
            .padding(8)
            .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
                .keyboardType(.decimalPad)
                .frame(width: 70)
            }
        }
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
            Text("\(setIndex + 1)")
                .font(.body.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 30)

            TextField(String(localized: "Reps"), text: Binding(
                get: { "\(entry.reps)" },
                set: { send(.updateSetReps(exerciseIndex: exerciseIndex, setIndex: setIndex, $0)) }
            ))
            .textFieldStyle(.plain)
            .padding(8)
            .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
            .keyboardType(.numberPad)

            TextField("kg", text: Binding(
                get: { entry.weight.map { "\(Int($0))" } ?? "" },
                set: { send(.updateSetWeight(exerciseIndex: exerciseIndex, setIndex: setIndex, $0)) }
            ))
            .textFieldStyle(.plain)
            .padding(8)
            .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
            .keyboardType(.decimalPad)
            .frame(width: 80)
        }
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
    private var cancelToolbarButton: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                send(.cancelTapped)
            } label: {
                Text(String(localized: "Cancel"))
            }
        }
    }

    @ToolbarContentBuilder
    private var addToolbarButton: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button {
                send(.addTapped)
            } label: {
                Text(String(localized: "Add"))
                    .fontWeight(.semibold)
            }
        }
    }
}

// MARK: - Preview

#Preview("WOD — AMRAP") {
    SetInputView(store: Store(initialState: SetInputFeature.State(
        wodName: "WOD 1",
        exercises: [
            ExerciseLogInput(exerciseType: .pullUps, category: .gymnastics, target: .reps(9), plannedReps: "9", actualReps: "9"),
            ExerciseLogInput(exerciseType: .thrusters, category: .olympicLifting, target: .reps(8), plannedReps: "8", plannedWeight: 50, actualWeight: 50, actualReps: "8"),
            ExerciseLogInput(exerciseType: .rowing, category: .cardio, target: .calories(17), plannedReps: "17 cal", actualReps: "17"),
        ],
        wodIndex: 0
    )) {
        SetInputFeature()
    })
}

#Preview("Strength — 5x10") {
    SetInputView(store: Store(initialState: SetInputFeature.State(
        wodName: "Strength",
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
        wodIndex: 1
    )) {
        SetInputFeature()
    })
}
