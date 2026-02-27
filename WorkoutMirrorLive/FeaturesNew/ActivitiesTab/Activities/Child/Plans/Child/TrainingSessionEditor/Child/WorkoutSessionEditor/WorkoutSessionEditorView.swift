//
//  WorkoutSessionEditorView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 21/02/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels
import SwiftUI

struct WorkoutSessionEditorView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<WorkoutSessionEditorFeature>

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                detailsGroupBox
                exercisesGroupBox
            }
            .padding()
        }
        .background(
            LinearGradient(
                colors: [store.color.opacity(0.25), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle(store.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .sheet(
            item: $store.scope(state: \.destination?.exerciseEditor, action: \.destination.exerciseEditor)
        ) { store in
            ExerciseEditorView(store: store)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button { store.send(.saveTapped) } label: {
                Text("Save").fontWeight(.semibold)
            }
            .disabled(store.isSaveDisabled)
        }
    }

    // MARK: - Details GroupBox

    private var detailsGroupBox: some View {
        GroupBox {
            VStack(spacing: 0) {
                nameRow
                Divider().padding(.leading)
                typeRow
                Divider().padding(.leading)
                timeCapRow
                Divider().padding(.leading)
                roundsRow
            }
        } label: {
            groupBoxHeader("Details")
        }
        .styledGroupBox()
    }

    private var nameRow: some View {
        editorRow {
            Text("Name").foregroundStyle(.secondary)
            Spacer()
            TextField("e.g. WOD 1", text: $store.draft.name)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 200)
        }
    }

    private var typeRow: some View {
        editorRow {
            Text("Type").foregroundStyle(.secondary)
            Spacer()
            Picker("", selection: Binding(
                get: { store.draft.type },
                set: { store.send(.binding(.set(\.draft.type, $0))) }
            )) {
                ForEach(ExerciseWorkoutType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
        }
    }

    private var timeCapRow: some View {
        editorRow {
            Text("Time Cap").foregroundStyle(.secondary)
            Spacer()
            if let timeCap = store.draft.timeCap {
                Stepper(
                    "\(timeCap) min",
                    value: Binding(
                        get: { timeCap },
                        set: { store.send(.binding(.set(\.draft.timeCap, $0))) }
                    ),
                    in: 1...120,
                    step: 1
                )
                .fixedSize()
            } else {
                Text("None").foregroundStyle(.secondary)
            }
            Toggle("", isOn: Binding(
                get: { store.draft.timeCap != nil },
                set: { store.send(.binding(.set(\.draft.timeCap, $0 ? store.draft.type.defaultTimeCapMinutes ?? 15 : nil))) }
            ))
            .labelsHidden()
            .tint(store.color)
            .fixedSize()
        }
    }

    private var roundsRow: some View {
        editorRow {
            Text("Rounds").foregroundStyle(.secondary)
            Spacer()
            if let rounds = store.draft.rounds {
                Stepper(
                    "\(rounds)",
                    value: Binding(
                        get: { rounds },
                        set: { store.send(.binding(.set(\.draft.rounds, $0))) }
                    ),
                    in: 1...99,
                    step: 1
                )
                .fixedSize()
            } else {
                Text("None").foregroundStyle(.secondary)
            }
            Toggle("", isOn: Binding(
                get: { store.draft.rounds != nil },
                set: { store.send(.binding(.set(\.draft.rounds, $0 ? 1 : nil))) }
            ))
            .labelsHidden()
            .tint(store.color)
            .fixedSize()
        }
    }

    // MARK: - Exercises GroupBox

    private var exercisesGroupBox: some View {
        GroupBox {
            if store.draft.exercises.isEmpty {
                emptyRow("No exercises yet")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(store.draft.exercises.enumerated()), id: \.element.id) { index, exercise in
                        if index > 0 { Divider().padding(.leading) }
                        Button { store.send(.exerciseTapped(exercise)) } label: {
                            exerciseRow(exercise)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                store.send(.exerciseDeleted(IndexSet(integer: index)))
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        } label: {
            groupBoxHeader("Exercises", addAction: { store.send(.exerciseAddTapped) })
        }
        .styledGroupBox()
    }

    private func exerciseRow(_ exercise: ExerciseSession) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                if let sets = exercise.sets, !sets.isEmpty {
                    Text(setsLabel(sets))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let target = exercise.target {
                    Text(targetLabel(target))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let weight = exercise.weight {
                Text(weightLabel(weight))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
    }

    private func setsLabel(_ sets: [SetScheme]) -> String {
        sets.map { set in
            var desc = "\(set.count)×\(set.reps)"
            if let intensity = set.intensity { desc += " @ \(intensity)" }
            return desc
        }.joined(separator: ", ")
    }

    private func targetLabel(_ target: ExerciseTarget) -> String {
        switch target {
        case .reps(let v):     return "\(v) reps"
        case .calories(let v): return "\(v) cal"
        case .meters(let v):   return "\(v)m"
        case .seconds(let v):  return "\(v)s"
        case .minutes(let v):  return "\(v) min"
        case .rounds(let v):   return "\(v) rounds"
        case .laps(let v):     return "\(v) laps"
        }
    }

    private func weightLabel(_ weight: WeightConfiguration) -> String {
        switch (weight.men, weight.women) {
        case let (m?, w?): return "\(m)/\(w) kg"
        case let (m?, nil): return "\(m) kg"
        case let (nil, w?): return "\(w) kg"
        default: return ""
        }
    }

    // MARK: - Helpers

    private func groupBoxHeader(_ title: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Divider()
        }
    }

    private func groupBoxHeader(_ title: String, addAction: @escaping () -> Void) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Button(action: addAction) {
                    Image(systemName: "plus")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
            Divider()
        }
    }

    @ViewBuilder
    private func editorRow<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack { content() }
            .padding(.vertical, 10)
            .padding(.horizontal, 4)
    }

    private func emptyRow(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
    }
}
