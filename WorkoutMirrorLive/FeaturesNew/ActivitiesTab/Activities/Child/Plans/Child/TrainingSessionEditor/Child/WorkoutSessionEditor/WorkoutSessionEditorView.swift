//
//  WorkoutSessionEditorView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 21/02/2026.
//

import ComposableArchitecture
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
        .navigationTitle(store.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("Save") { store.send(.saveTapped) }
                .fontWeight(.semibold)
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
            .fixedSize()
        }
    }

    // MARK: - Exercises GroupBox

    private var exercisesGroupBox: some View {
        GroupBox {
            emptyRow("No exercises yet")
        } label: {
            groupBoxHeader("Exercises")
        }
        .styledGroupBox()
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
