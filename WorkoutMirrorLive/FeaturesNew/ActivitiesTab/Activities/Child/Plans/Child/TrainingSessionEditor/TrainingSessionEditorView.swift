//
//  TrainingSessionEditorView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 21/02/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

struct TrainingSessionEditorView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<TrainingSessionEditorFeature>

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                detailsGroupBox
                warmupGroupBox
                workoutsGroupBox
                cooldownGroupBox
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
        .alert($store.scope(state: \.alert, action: \.alert))
        .navigationDestination(
            item: $store.scope(state: \.destination?.workoutEditor, action: \.destination.workoutEditor)
        ) { store in
            WorkoutSessionEditorView(store: store)
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
                titleRow
                Divider().padding(.leading)
                dateRow
                Divider().padding(.leading)
                activityRow
                Divider().padding(.leading)
                locationRow
            }
        } label: {
            groupBoxHeader("Details")
        }
        .styledGroupBox()
    }

    private var titleRow: some View {
        editorRow {
            Text("Title").foregroundStyle(.secondary)
            Spacer()
            TextField("Workout name", text: $store.draft.title)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 200)
        }
    }

    private var dateRow: some View {
        editorRow {
            Text("Date").foregroundStyle(.secondary)
            Spacer()
            DatePicker("", selection: $store.draft.date, displayedComponents: .date)
                .labelsHidden()
        }
    }

    private var activityRow: some View {
        editorRow {
            Text("Activity").foregroundStyle(.secondary)
            Spacer()
            Picker("", selection: Binding(
                get: { store.draft.activity },
                set: { store.send(.binding(.set(\.draft.activity, $0))) }
            )) {
                ForEach(TrainingSessionEditorFeature.State.supportedActivities, id: \.self) { type in
                    Text(type.title).tag(type)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
        }
    }

    private var locationRow: some View {
        editorRow {
            Text("Location").foregroundStyle(.secondary)
            Spacer()
            Picker("", selection: Binding(
                get: { store.draft.location },
                set: { store.send(.binding(.set(\.draft.location, $0))) }
            )) {
                ForEach(WorkoutLocationType.allCases, id: \.self) { loc in
                    Text(loc.title).tag(loc)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .frame(width: 150)
        }
    }

    // MARK: - Warmup GroupBox

    private var warmupGroupBox: some View {
        GroupBox {
            if let warmUp = store.draft.warmUp {
                VStack(spacing: 0) {
                    warmupDurationRow(warmUp)
                    Divider().padding(.leading)
                    warmupNotesSection
                }
            } else {
                emptyRow("No warmup")
            }
        } label: {
            groupBoxHeader("Warmup", isOn: Binding(
                get: { store.draft.warmUp != nil },
                set: { _ in store.send(.warmUpToggled) }
            ))
        }
        .styledGroupBox()
    }

    private func warmupDurationRow(_ warmUp: WarmUpSession) -> some View {
        editorRow {
            Text("Duration").foregroundStyle(.secondary)
            Spacer()
            Stepper(
                "\(warmUp.time ?? 10) min",
                value: Binding(
                    get: { warmUp.time ?? 10 },
                    set: { store.send(.warmUpTimeChanged($0)) }
                ),
                in: 1...120,
                step: 1
            )
            .fixedSize()
        }
    }

    private var warmupNotesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            editorRow {
                Text("Description").foregroundStyle(.secondary)
                Spacer()
                Menu {
                    if store.draft.workouts.isEmpty {
                        Text("Add workouts first to generate warmup")
                    } else {
                        Button {
                            store.send(.warmUpGenerateTapped)
                        } label: {
                            Label("Generate with AI", systemImage: "apple.intelligence")
                        }
                    }
                } label: {
                    Image(systemName: "apple.intelligence")
                        .foregroundStyle(.tint)
                }
            }
            Divider().padding(.leading)
            if store.isGeneratingWarmUpNotes {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Generating warmup...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            } else {
                TextField("e.g. 5 min light jog, dynamic stretching, mobility...", text: Binding(
                    get: { store.draft.warmUp?.description ?? "" },
                    set: { newDesc in
                        if var warmUp = store.draft.warmUp {
                            warmUp.description = newDesc
                            store.send(.binding(.set(\.draft.warmUp, warmUp)))
                        }
                    }
                ), axis: .vertical)
                .padding(.horizontal, 4)
                .padding(.vertical, 10)
            }
        }
    }

    // MARK: - Workouts GroupBox

    private var workoutsGroupBox: some View {
        GroupBox {
            if store.draft.workouts.isEmpty {
                emptyRow("No workouts")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(store.draft.workouts.enumerated()), id: \.offset) { index, workout in
                        if index > 0 { Divider().padding(.leading) }
                        Button { store.send(.workoutTapped(workout)) } label: {
                            editorRow {
                                workoutRow(workout)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        } label: {
            groupBoxHeader("Workouts", addAction: { store.send(.workoutAddTapped) })
        }
        .styledGroupBox()
    }

    private func workoutRow(_ workout: WorkoutSessionNew) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                HStack(spacing: 6) {
                    Text(workout.type.displayName.uppercased())
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(workout.type.color.opacity(0.8))
                        .cornerRadius(4)
                    Text("\(workout.exercises.count) exercises")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let timeCap = workout.timeCap {
                Text("\(timeCap) min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Cooldown GroupBox

    private var cooldownGroupBox: some View {
        GroupBox {
            if let coolDown = store.draft.coolDown {
                VStack(spacing: 0) {
                    cooldownDurationRow(coolDown)
                    Divider().padding(.leading)
                    cooldownNotesSection
                }
            } else {
                emptyRow("No cooldown")
            }
        } label: {
            groupBoxHeader("Cooldown", isOn: Binding(
                get: { store.draft.coolDown != nil },
                set: { _ in store.send(.coolDownToggled) }
            ))
        }
        .styledGroupBox()
    }

    private func cooldownDurationRow(_ coolDown: CoolDownSession) -> some View {
        editorRow {
            Text("Duration").foregroundStyle(.secondary)
            Spacer()
            Stepper(
                "\(coolDown.time ?? 10) min",
                value: Binding(
                    get: { coolDown.time ?? 10 },
                    set: { store.send(.coolDownTimeChanged($0)) }
                ),
                in: 1...120,
                step: 1
            )
            .fixedSize()
        }
    }

    private var cooldownNotesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            editorRow {
                Text("Description").foregroundStyle(.secondary)
                Spacer()
                Menu {
                    if store.draft.workouts.isEmpty {
                        Text("Add workouts first to generate cooldown")
                    } else {
                        Button {
                            store.send(.coolDownGenerateTapped)
                        } label: {
                            Label("Generate with AI", systemImage: "apple.intelligence")
                        }
                    }
                } label: {
                    Image(systemName: "apple.intelligence")
                        .foregroundStyle(.tint)
                }
            }
            Divider().padding(.leading)
            if store.isGeneratingCoolDownNotes {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Generating cooldown...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            } else {
                TextField("e.g. 10 min walk, static stretching, foam rolling...", text: Binding(
                    get: { store.draft.coolDown?.description ?? "" },
                    set: { newDesc in
                        if var coolDown = store.draft.coolDown {
                            coolDown.description = newDesc
                            store.send(.binding(.set(\.draft.coolDown, coolDown)))
                        }
                    }
                ), axis: .vertical)
                .padding(.horizontal, 4)
                .padding(.vertical, 10)
            }
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
