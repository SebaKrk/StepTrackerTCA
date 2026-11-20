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

@ViewAction(for: WorkoutSessionEditorFeature.self)
struct WorkoutSessionEditorView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<WorkoutSessionEditorFeature>

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                detailsGroupBox
                if store.draft.type != .intervals && !store.draft.exercises.isEmpty {
                    exercisesGroupBox
                }
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            bottomBar
        }
        .background(
            LinearGradient(
                colors: [store.color.opacity(0.2), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle(store.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .alert($store.scope(state: \.alert, action: \.alert))
        .navigationDestination(
            item: $store.scope(state: \.destination?.exerciseEditor, action: \.destination.exerciseEditor)
        ) { store in
            ExerciseEditorView(store: store)
        }
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

    // MARK: - Details GroupBox

    private var detailsGroupBox: some View {
        GroupBox {
            VStack(spacing: 0) {
                nameRow
                Divider().padding(.leading)
                typeRow
                if store.draft.type == .intervals {
                    Divider().padding(.leading)
                    intervalWorkRow
                    Divider().padding(.leading)
                    intervalRestRow
                    Divider().padding(.leading)
                    intervalRoundsRow
                } else {
                    Divider().padding(.leading)
                    timeCapRow
                    // An AMRAP's rounds are the result, not the prescription — a planned
                    // number here would be read as work the athlete is known to have done.
                    if store.draft.type != .amrap {
                        Divider().padding(.leading)
                        roundsRow
                    }
                    if store.draft.type == .forTime {
                        Divider().padding(.leading)
                        fitnessRunRow
                    }
                }
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

    private var fitnessRunRow: some View {
        editorRow {
            Text("Run before every station").foregroundStyle(.secondary)
            Spacer()
            if let fitnessRun = store.draft.fitnessRun {
                Stepper(
                    "\(fitnessRun.runMeters) m",
                    value: Binding(
                        get: { fitnessRun.runMeters },
                        set: { store.send(.binding(.set(\.draft.fitnessRun, FitnessRunPlan(runMeters: $0)))) }
                    ),
                    in: 100...5000,
                    step: 100
                )
                .fixedSize()
            }
            Toggle("", isOn: Binding(
                get: { store.draft.fitnessRun != nil },
                set: { store.send(.binding(.set(\.draft.fitnessRun, $0 ? FitnessRunPlan(runMeters: 1000) : nil))) }
            ))
            .labelsHidden()
            .tint(store.color)
            .fixedSize()
        }
        .animation(.default, value: store.draft.fitnessRun)
    }

    // MARK: - Interval Rows (Rounds type)

    /// Reducer seeds `draft.interval` on switching to Rounds; the fallback here
    /// only guards a transient render before that binding lands.
    private var intervalDraft: IntervalPlan {
        store.draft.interval ?? IntervalPlan(workSeconds: 30, restSeconds: 30, rounds: 12)
    }

    private var intervalWorkRow: some View {
        editorRow {
            Text("Work").foregroundStyle(.secondary)
            Spacer()
            Stepper(
                intervalSecondsLabel(intervalDraft.workSeconds),
                value: Binding(
                    get: { intervalDraft.workSeconds },
                    set: { store.send(.binding(.set(\.draft.interval, IntervalPlan(
                        workSeconds: $0,
                        restSeconds: intervalDraft.restSeconds,
                        rounds: intervalDraft.rounds
                    )))) }
                ),
                in: 10...600,
                step: 5
            )
            .fixedSize()
        }
    }

    private var intervalRestRow: some View {
        editorRow {
            Text("Rest").foregroundStyle(.secondary)
            Spacer()
            Stepper(
                intervalSecondsLabel(intervalDraft.restSeconds),
                value: Binding(
                    get: { intervalDraft.restSeconds },
                    set: { store.send(.binding(.set(\.draft.interval, IntervalPlan(
                        workSeconds: intervalDraft.workSeconds,
                        restSeconds: $0,
                        rounds: intervalDraft.rounds
                    )))) }
                ),
                in: 0...600,
                step: 5
            )
            .fixedSize()
        }
    }

    private var intervalRoundsRow: some View {
        editorRow {
            Text("Rounds").foregroundStyle(.secondary)
            Spacer()
            Stepper(
                "\(intervalDraft.rounds)",
                value: Binding(
                    get: { intervalDraft.rounds },
                    set: { store.send(.binding(.set(\.draft.interval, IntervalPlan(
                        workSeconds: intervalDraft.workSeconds,
                        restSeconds: intervalDraft.restSeconds,
                        rounds: $0
                    )))) }
                ),
                in: 1...99,
                step: 1
            )
            .fixedSize()
        }
    }

    private func intervalSecondsLabel(_ seconds: Int) -> String {
        seconds < 60
            ? "\(seconds) s"
            : String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            if store.mode == .edit {
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
            }
            Spacer()
            if store.draft.type != .intervals {
                Button {
                    send(.exerciseAddTapped)
                } label: {
                    Image(systemName: "plus")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(store.color)
                        .frame(width: 52, height: 52)
                        .glassEffect(.regular.interactive(), in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Exercises GroupBox

    private var exercisesGroupBox: some View {
        GroupBox {
            VStack(spacing: 0) {
                ForEach(Array(store.draft.exercises.enumerated()), id: \.element.id) { index, exercise in
                    if index > 0 { Divider().padding(.leading) }
                    HStack(spacing: 8) {
                        Button {
                            send(.exerciseTapped(exercise))
                        } label: {
                            exerciseRow(exercise)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            if index > 0 {
                                Button {
                                    send(.exerciseMoved(from: IndexSet(integer: index), to: index - 1))
                                } label: {
                                    Label("Move up", systemImage: "arrow.up")
                                }
                            }
                            if index < store.draft.exercises.count - 1 {
                                Button {
                                    send(.exerciseMoved(from: IndexSet(integer: index), to: index + 2))
                                } label: {
                                    Label("Move down", systemImage: "arrow.down")
                                }
                            }
                            Button(role: .destructive) {
                                send(.exerciseDeleted(IndexSet(integer: index)))
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        reorderHandle(exercise)
                    }
                    .dropDestination(for: String.self) { droppedIds, _ in
                        exerciseDropped(droppedIds, onto: index)
                    }
                }
            }
            .animation(.default, value: store.draft.exercises)
        } label: {
            groupBoxHeader(store.draft.fitnessRun == nil ? "Exercises" : "Stations")
        }
        .styledGroupBox()
    }

    /// Grip that lifts a row; dropping it on another row moves it there.
    private func reorderHandle(_ exercise: ExerciseSession) -> some View {
        Image(systemName: "line.3.horizontal")
            .font(.body)
            .foregroundStyle(.tertiary)
            .frame(width: 32, height: 36)
            .contentShape(Rectangle())
            .draggable(exercise.id.uuidString) {
                Text(exercise.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }
            .accessibilityLabel(Text("Reorder"))
    }

    /// Turns a drop into the reducer's move; `Array.move` wants the slot after the row when moving down.
    private func exerciseDropped(_ droppedIds: [String], onto index: Int) -> Bool {
        guard let droppedId = droppedIds.first,
              let from = store.draft.exercises.firstIndex(where: { $0.id.uuidString == droppedId }),
              from != index
        else { return false }
        send(.exerciseMoved(from: IndexSet(integer: from), to: from < index ? index + 1 : index))
        return true
    }

    private func exerciseRow(_ exercise: ExerciseSession) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                if let info = exercise.info, !info.isEmpty {
                    Text(info)
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

// MARK: - Previews

#Preview("Rounds — boxing intervals") {
    NavigationStack {
        WorkoutSessionEditorView(
            store: Store(
                initialState: WorkoutSessionEditorFeature.State(
                    workout: WorkoutSessionNew(
                        name: "Boxing rounds",
                        type: .intervals,
                        timeCap: nil,
                        rounds: nil,
                        exercises: [],
                        interval: IntervalPlan(workSeconds: 180, restSeconds: 60, rounds: 10)
                    )
                )
            ) {
                WorkoutSessionEditorFeature()
            }
        )
    }
}

#Preview("AMRAP — classic WOD") {
    NavigationStack {
        WorkoutSessionEditorView(
            store: Store(
                initialState: WorkoutSessionEditorFeature.State(
                    workout: WorkoutSessionNew(
                        name: "Cindy",
                        type: .amrap,
                        timeCap: 20,
                        rounds: nil,
                        exercises: []
                    )
                )
            ) {
                WorkoutSessionEditorFeature()
            }
        )
    }
}
