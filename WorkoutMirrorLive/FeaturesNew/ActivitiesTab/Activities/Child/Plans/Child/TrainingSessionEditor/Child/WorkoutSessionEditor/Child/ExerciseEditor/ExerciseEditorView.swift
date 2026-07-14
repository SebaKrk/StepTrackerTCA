//
//  ExerciseEditorView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 21/02/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

@ViewAction(for: ExerciseEditorFeature.self)
struct ExerciseEditorView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<ExerciseEditorFeature>

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                exerciseGroupBox
                targetGroupBox
                weightGroupBox
                notesGroupBox
            }
            .padding()
        }
        .navigationTitle(store.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .alert($store.scope(state: \.alert, action: \.alert))
        .safeAreaInset(edge: .bottom) {
            if store.mode == .edit {
                bottomBar
            }
        }
        .navigationDestination(
            item: $store.scope(state: \.destination?.picker, action: \.destination.picker)
        ) { store in
            ExercisePickerView(store: store)
        }
        .background(
            LinearGradient(
                colors: [store.color.opacity(0.25), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button { send(.saveTapped) } label: {
                Text("Save").fontWeight(.semibold)
            }
            .disabled(store.isSaveDisabled)
        }
    }

    // MARK: - Exercise GroupBox

    private var exerciseGroupBox: some View {
        GroupBox {
            VStack(spacing: 0) {
                exerciseTypeRow
                if store.draft.type == .unknown {
                    Divider().padding(.leading)
                    customNameRow
                }
            }
        } label: {
            groupBoxHeader("Exercise")
        }
        .styledGroupBox()
    }

    private var exerciseTypeRow: some View {
        editorRow {
            Text("Type").foregroundStyle(.secondary)
            Spacer()
            Button { send(.pickExerciseTapped) } label: {
                HStack(spacing: 4) {
                    Text(store.draft.type.displayName)
                        .foregroundStyle(.primary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var customNameRow: some View {
        editorRow {
            Text("Name").foregroundStyle(.secondary)
            Spacer()
            TextField("e.g. Wall Sit", text: Binding(
                get: { store.draft.customName ?? "" },
                set: { store.send(.binding(.set(\.draft.customName, $0.isEmpty ? nil : $0))) }
            ))
            .multilineTextAlignment(.trailing)
            .frame(maxWidth: 200)
        }
    }

    // MARK: - Target GroupBox

    private var targetGroupBox: some View {
        GroupBox {
            VStack(spacing: 0) {
                targetTypeRow
                Divider().padding(.leading)
                targetValueRow
            }
        } label: {
            groupBoxHeader("Target", isOn: Binding(
                get: { store.draft.target != nil },
                set: { enabled in
                    store.send(.binding(.set(
                        \.draft.target,
                        enabled ? .reps(10) : nil
                    )))
                }
            ))
        }
        .styledGroupBox()
    }

    private var targetTypeRow: some View {
        editorRow {
            Text("Type").foregroundStyle(.secondary)
            Spacer()
            Picker("", selection: Binding(
                get: { store.draft.target?.targetType ?? .reps },
                set: { send(.targetTypeChanged($0)) }
            )) {
                ForEach(ExerciseTargetType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .disabled(store.draft.target == nil)
        }
    }

    private var targetValueRow: some View {
        editorRow {
            Text("Value").foregroundStyle(.secondary)
            Spacer()
            if let target = store.draft.target {
                HStack(spacing: 4) {
                    TextField("", text: Binding(
                        get: { "\(target.value)" },
                        set: { if let v = Int($0), v > 0 { send(.targetValueChanged(v)) } }
                    ))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 70)
                    Text(target.targetType.displayName.lowercased())
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("None").foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Weight GroupBox

    private var weightGroupBox: some View {
        GroupBox {
            if let weight = store.draft.weight {
                VStack(spacing: 0) {
                    weightRow("Men", value: Binding(
                        get: { weight.men ?? 0 },
                        set: { store.send(.binding(.set(\.draft.weight, WeightConfiguration(men: $0, women: weight.women)))) }
                    ))
                    Divider().padding(.leading)
                    weightRow("Women", value: Binding(
                        get: { weight.women ?? 0 },
                        set: { store.send(.binding(.set(\.draft.weight, WeightConfiguration(men: weight.men, women: $0)))) }
                    ))
                }
            } else {
                emptyRow("No weight prescribed")
            }
        } label: {
            groupBoxHeader("Weight", isOn: Binding(
                get: { store.draft.weight != nil },
                set: { enabled in
                    store.send(.binding(.set(
                        \.draft.weight,
                        enabled ? WeightConfiguration(men: 60, women: 40) : nil
                    )))
                }
            ))
        }
        .styledGroupBox()
    }

    private func weightRow(_ label: String, value: Binding<Int>) -> some View {
        editorRow {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Stepper("\(value.wrappedValue) kg", value: value, in: 1...500, step: 1)
                .fixedSize()
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            Button {
                send(.deleteTapped)
            } label: {
                Image(systemName: "trash")
                    .font(.title3)
                    .foregroundStyle(.red.opacity(0.6))
                    .frame(width: 52, height: 52)
                    .glassEffect(.regular.interactive(), in: Circle())
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Notes GroupBox

    private var notesGroupBox: some View {
        GroupBox {
            TextField("Coaching cues, scaling options...", text: $store.draft.info, axis: .vertical)
                .lineLimit(2...)
                .padding(.horizontal, 4)
                .padding(.vertical, 10)
        } label: {
            groupBoxHeader("Notes")
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

    private func groupBoxHeader(_ title: String, isOn: Binding<Bool>) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Toggle("", isOn: isOn)
                    .labelsHidden()
                    .tint(store.color)
                    .fixedSize()
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
