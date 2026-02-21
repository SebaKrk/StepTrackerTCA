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
                    if warmUp.description != nil {
                        Divider().padding(.leading)
                        warmupDescriptionRow(warmUp)
                    }
                }
            } else {
                emptyRow("No warmup")
            }
        } label: {
            groupBoxHeader("Warmup")
        }
        .styledGroupBox()
    }

    private func warmupDurationRow(_ warmUp: WarmUpSession) -> some View {
        editorRow(isLast: warmUp.description == nil) {
            Text("Duration").foregroundStyle(.secondary)
            Spacer()
            Text(warmUp.time.map { "\($0) min" } ?? "–")
                .foregroundStyle(.primary)
        }
    }

    private func warmupDescriptionRow(_ warmUp: WarmUpSession) -> some View {
        editorRow(isLast: true) {
            Text(warmUp.description ?? "")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
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
                        editorRow(isLast: index == store.draft.workouts.count - 1) {
                            workoutRow(workout)
                        }
                    }
                }
            }
        } label: {
            groupBoxHeader("Workouts")
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
        }
    }

    // MARK: - Cooldown GroupBox

    private var cooldownGroupBox: some View {
        GroupBox {
            if let coolDown = store.draft.coolDown {
                VStack(spacing: 0) {
                    cooldownDurationRow(coolDown)
                    if coolDown.description != nil {
                        Divider().padding(.leading)
                        cooldownDescriptionRow(coolDown)
                    }
                }
            } else {
                emptyRow("No cooldown")
            }
        } label: {
            groupBoxHeader("Cooldown")
        }
        .styledGroupBox()
    }

    private func cooldownDurationRow(_ coolDown: CoolDownSession) -> some View {
        editorRow(isLast: coolDown.description == nil) {
            Text("Duration").foregroundStyle(.secondary)
            Spacer()
            Text(coolDown.time.map { "\($0) min" } ?? "–")
                .foregroundStyle(.primary)
        }
    }

    private func cooldownDescriptionRow(_ coolDown: CoolDownSession) -> some View {
        editorRow(isLast: true) {
            Text(coolDown.description ?? "")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
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
        isLast: Bool = false,
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
