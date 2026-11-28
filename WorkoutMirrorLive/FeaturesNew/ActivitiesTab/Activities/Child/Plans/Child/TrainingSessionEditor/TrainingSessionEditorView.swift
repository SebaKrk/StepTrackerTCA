//
//  TrainingSessionEditorView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 21/02/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

@ViewAction(for: TrainingSessionEditorFeature.self)
struct TrainingSessionEditorView: View {

    // MARK: - Properties

    /// Editor store; every edit goes through it as a view action or a binding.
    @Bindable var store: StoreOf<TrainingSessionEditorFeature>

    // MARK: - Body

    var body: some View {
        editorScreen
            .navigationTitle(store.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .alert($store.scope(state: \.alert, action: \.alert))
            .safeAreaInset(edge: .bottom) {
                bottomBar
            }
            .navigationDestination(item: workoutEditorStore) { store in
                WorkoutSessionEditorView(store: store)
            }
            .navigationDestination(item: warmUpBlockEditorStore) { store in
                WorkoutSessionEditorView(store: store)
            }
            .navigationDestination(item: coolDownBlockEditorStore) { store in
                WorkoutSessionEditorView(store: store)
            }
    }

    // MARK: - Structure

    private var editorScreen: some View {
        cards
            .scrollDismissesKeyboard(.interactively)
            .dismissesKeyboardOnBackgroundTap()
            .modifier(dragHaptics)
            .background(screenBackground)
    }

    private var cards: some View {
        ScrollView {
            VStack(spacing: 12) {
                detailsCard
                warmUpCard
                workoutsCard
                coolDownCard
            }
            .padding()
        }
    }

    private var detailsCard: some View {
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

    private var warmUpCard: some View {
        GroupBox {
            if store.draft.warmUp != nil {
                warmUpContent
            } else {
                emptyRow("No warmup")
            }
        } label: {
            groupBoxHeader("Warmup", isOn: warmUpToggle)
        }
        .styledGroupBox()
    }

    private var workoutsCard: some View {
        GroupBox {
            if store.draft.workouts.isEmpty {
                emptyRow("No workouts")
            } else {
                workoutList
            }
        } label: {
            groupBoxHeader("Workouts")
        }
        .styledGroupBox()
    }

    private var coolDownCard: some View {
        GroupBox {
            if store.draft.coolDown != nil {
                coolDownContent
            } else {
                emptyRow("No cooldown")
            }
        } label: {
            groupBoxHeader("Cooldown", isOn: coolDownToggle)
        }
        .styledGroupBox()
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            saveButton
        }
    }

    private var bottomBar: some View {
        HStack {
            if store.mode == .edit {
                deleteButton
            }
            Spacer()
            addWorkoutButton
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Details Rows

    private var titleRow: some View {
        editorRow {
            rowLabel("Title")
            Spacer()
            TextField("Workout name", text: $store.draft.title)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 200)
        }
    }

    private var dateRow: some View {
        editorRow {
            rowLabel("Date")
            Spacer()
            DatePicker("", selection: $store.draft.date, displayedComponents: .date)
                .labelsHidden()
        }
    }

    private var activityRow: some View {
        editorRow {
            rowLabel("Activity")
            Spacer()
            Picker("", selection: $store.draft.activity) {
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
            rowLabel("Location")
            Spacer()
            Picker("", selection: $store.draft.location) {
                ForEach(WorkoutLocationType.allCases, id: \.self) { location in
                    Text(location.title).tag(location)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .frame(width: 150)
        }
    }

    // MARK: - Side Sections

    private var warmUpContent: some View {
        SideSectionView(
            section: store.warmUpSection,
            addBlockTitle: "Add activation",
            notesPlaceholder: "e.g. 5 min light jog, dynamic stretching, mobility...",
            accent: store.color,
            onMinutesChange: changeWarmUpMinutes,
            onNotesChange: changeWarmUpNotes,
            onEditBlock: editWarmUpBlock,
            onRemoveBlock: removeWarmUpBlock,
            onSwap: swapWarmUpParts,
            onLift: liftSidePart,
            onDragEnd: endSideDrag,
            onTargeted: targetSidePart,
            onDrop: dropSidePart
        )
    }

    private var coolDownContent: some View {
        SideSectionView(
            section: store.coolDownSection,
            addBlockTitle: "Add finisher",
            notesPlaceholder: "e.g. 10 min walk, static stretching, foam rolling...",
            accent: store.color,
            onMinutesChange: changeCoolDownMinutes,
            onNotesChange: changeCoolDownNotes,
            onEditBlock: editCoolDownBlock,
            onRemoveBlock: removeCoolDownBlock,
            onSwap: swapCoolDownParts,
            onLift: liftSidePart,
            onDragEnd: endSideDrag,
            onTargeted: targetSidePart,
            onDrop: dropSidePart
        )
    }

    private var warmUpToggle: Binding<Bool> {
        Binding(get: { store.draft.warmUp != nil }, set: { _ in toggleWarmUp() })
    }

    private var coolDownToggle: Binding<Bool> {
        Binding(get: { store.draft.coolDown != nil }, set: { _ in toggleCoolDown() })
    }

    // MARK: - Side Section Events

    private func toggleWarmUp() { send(.warmUpToggled) }
    private func changeWarmUpMinutes(_ minutes: Int) { send(.warmUpTimeChanged(minutes)) }
    private func changeWarmUpNotes(_ notes: String) { send(.warmUpNotesChanged(notes)) }
    private func editWarmUpBlock() { send(.warmUpBlockEditTapped) }
    private func removeWarmUpBlock() { send(.warmUpBlockRemoveTapped) }
    private func swapWarmUpParts() { send(.warmUpPartsSwapped) }

    private func toggleCoolDown() { send(.coolDownToggled) }
    private func changeCoolDownMinutes(_ minutes: Int) { send(.coolDownTimeChanged(minutes)) }
    private func changeCoolDownNotes(_ notes: String) { send(.coolDownNotesChanged(notes)) }
    private func editCoolDownBlock() { send(.coolDownBlockEditTapped) }
    private func removeCoolDownBlock() { send(.coolDownBlockRemoveTapped) }
    private func swapCoolDownParts() { send(.coolDownPartsSwapped) }

    /// iOS 27 clears the lift when the drag ends, so every lift changes state; iOS 26 plays its haptic imperatively instead.
    private var liftHapticTrigger: SidePart? {
        guard #available(iOS 27, *) else { return nil }
        return store.draggedSidePart
    }

    private func liftSidePart(_ part: SidePart) {
        send(.sidePartLifted(part))
    }

    private func endSideDrag() {
        send(.sidePartDragEnded)
    }

    private func targetSidePart(_ part: SidePart, isTargeted: Bool) {
        send(.sidePartTargeted(part, isTargeted: isTargeted))
    }

    /// SwiftUI needs the answer right away; the rule lives on `SidePart` and the reducer checks it again.
    private func dropSidePart(_ dropped: SidePart, onto target: SidePart) -> Bool {
        guard dropped.canSwap(with: target) else { return false }
        send(.sidePartDropped(dropped, onto: target))
        return true
    }

    // MARK: - Workouts

    private var workoutList: some View {
        VStack(spacing: 0) {
            ForEach(Array(store.draft.workouts.enumerated()), id: \.offset) { index, workout in
                if index > 0 { Divider().padding(.leading) }
                workoutButton(workout)
            }
        }
    }

    private func workoutButton(_ workout: WorkoutSessionNew) -> some View {
        Button {
            send(.workoutTapped(workout))
        } label: {
            editorRow {
                workoutRow(workout)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func workoutRow(_ workout: WorkoutSessionNew) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                workoutName(workout.name)
                HStack(spacing: 6) {
                    workoutTypeBadge(workout.type)
                    workoutExerciseCount(workout.exercises.count)
                }
            }
            Spacer()
            if let timeCap = workout.timeCap {
                workoutTimeCap(timeCap)
            }
            disclosureChevron
        }
    }

    // MARK: - Buttons

    private var saveButton: some View {
        Button {
            send(.saveTapped)
        } label: {
            Text("Save").fontWeight(.semibold)
        }
        .disabled(store.isSaveDisabled)
    }

    private var deleteButton: some View {
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

    private var addWorkoutButton: some View {
        Button {
            send(.workoutAddTapped)
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

    // MARK: - Navigation

    private var workoutEditorStore: Binding<StoreOf<WorkoutSessionEditorFeature>?> {
        $store.scope(state: \.destination?.workoutEditor, action: \.destination.workoutEditor)
    }

    private var warmUpBlockEditorStore: Binding<StoreOf<WorkoutSessionEditorFeature>?> {
        $store.scope(state: \.destination?.warmUpBlockEditor, action: \.destination.warmUpBlockEditor)
    }

    private var coolDownBlockEditorStore: Binding<StoreOf<WorkoutSessionEditorFeature>?> {
        $store.scope(state: \.destination?.coolDownBlockEditor, action: \.destination.coolDownBlockEditor)
    }

    // MARK: - Implementation

    private var dragHaptics: DragHapticsModifier {
        DragHapticsModifier(
            liftedPart: liftHapticTrigger,
            dropTarget: store.sidePartDropTarget,
            warmUpOrder: store.draft.warmUp?.order,
            coolDownOrder: store.draft.coolDown?.order
        )
    }

    private var screenBackground: some View {
        LinearGradient(
            colors: [store.color.opacity(0.2), .clear],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private func rowLabel(_ title: LocalizedStringKey) -> some View {
        Text(title).foregroundStyle(.secondary)
    }

    private func workoutName(_ name: String) -> some View {
        Text(name)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(.primary)
    }

    private func workoutTypeBadge(_ type: ExerciseWorkoutType) -> some View {
        Text(type.displayName.uppercased())
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(type.color.opacity(0.8))
            .cornerRadius(4)
    }

    private func workoutExerciseCount(_ count: Int) -> some View {
        Text("\(count) exercises")
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private func workoutTimeCap(_ minutes: Int) -> some View {
        Text("\(minutes) min")
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private var disclosureChevron: some View {
        Image(systemName: "chevron.right")
            .font(.caption)
            .foregroundStyle(.tertiary)
    }

    private func groupBoxHeader(_ title: LocalizedStringKey) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Divider()
        }
    }

    private func groupBoxHeader(_ title: LocalizedStringKey, isOn: Binding<Bool>) -> some View {
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

    private func editorRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack { content() }
            .padding(.vertical, 10)
            .padding(.horizontal, 4)
    }

    private func emptyRow(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
    }
}
