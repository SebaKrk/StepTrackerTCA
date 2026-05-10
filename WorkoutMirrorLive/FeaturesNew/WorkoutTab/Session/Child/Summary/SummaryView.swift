//
//  SummaryView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 30/08/2025.
//

import ComposableArchitecture
import Commons
import HealthKit
import SwiftUI
import SharedModels
import Textual

private enum FocusField: Hashable {
    case score(Int)
    case note(Int)
    case exerciseReps(wodIndex: Int, exerciseIndex: Int)
    case exerciseWeight(wodIndex: Int, exerciseIndex: Int)
}

@ViewAction(for: SummaryFeature.self)
struct SummaryView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<SummaryFeature>
    @FocusState private var focusedField: FocusField?
    
    // MARK: - Body
    
    var body: some View {
        Group {
            switch store.viewState {
            case .saving:
                savingView
            case .loading:
                loadingView
            case .successfullyLoaded:
                summaryView
            case .failed:
                failedView
            }
        }
        .onAppear {
            send(.viewDidAppear)
        }
    }
    
    // MARK: - Saving

    private var savingView: some View {
        VStack(spacing: 12) {
            Spacer()
            ProgressView()
                .controlSize(.large)
            Text(String(localized: "Saving workout..."))
                .font(.headline)
            Text(String(localized: "Waiting for Apple Watch"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .transition(.opacity)
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView(String(localized: "Loading summary..."))
            Spacer()
        }
        .transition(.opacity)
    }
    
    // MARK: - Failed

    private var failedView: some View {
        ContentUnavailableView {
            Label(String(localized: "Could not load summary"), systemImage: "exclamationmark.triangle")
        } description: {
            VStack(spacing: 8) {
                Text("Something went wrong while saving your workout.")
                #if DEBUG
                Text(store.failureDebugInfo)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                #endif
            }
        } actions: {
            closeButton
        }
    }

    private var closeButton: some View {
        Button {
            send(.closeButtonTapped)
        } label: {
            Text(String(localized: "Close"))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
        }
        .buttonStyle(.bordered)
        .tint(.gray)
    }

    // MARK: - Summary
    
    @ViewBuilder
    private var summaryView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 12) {
                    if let workout = store.summary?.workout {
                        headerCard(workout: workout)
                        metricsGrid(workout: workout)
                    }
                    if !store.resultInputs.isEmpty {
                        wodResultsSection
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
                .contentShape(Rectangle())
                .onTapGesture { focusedField = nil }
            }
            .contentMargins(.bottom, 80, for: .scrollContent)
            .scrollDismissesKeyboard(.interactively)
            .task(id: focusedField) {
                guard let field = focusedField else { return }
                try? await Task.sleep(nanoseconds: 350_000_000)
                withAnimation(.easeInOut(duration: 0.25)) {
                    proxy.scrollTo(field, anchor: .center)
                }
            }
        }
        .background(
            LinearGradient(
                colors: [Color.gray.opacity(0.2), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle(String(localized: "Summary"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .alert(store: store.scope(state: \.$discardAlert, action: \.alert))
        .sheet(item: $store.scope(state: \.setInput, action: \.setInput)) { store in
            SetInputView(store: store)
        }
    }
    
    // MARK: - Header Card
    
    private func headerCard(workout: HKWorkout) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(workout.workoutActivityType.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(workout.duration.formattedDuration())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: workout.workoutActivityType.iconNameSimple)
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("\(workout.startDate.formatted(date: .omitted, time: .shortened)) – \(workout.endDate.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(workout.startDate.formatted(.dateTime.weekday(.wide)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .styledGroupBox()
    }
    
    // MARK: - Metrics Grid
    
    private func metricsGrid(workout: HKWorkout) -> some View {
        let hkCalories = workout.statistics(for: .init(.activeEnergyBurned))?
            .sumQuantity()
            .map { Int($0.doubleValue(for: .kilocalorie())) }
        let metricsEnergy = store.summary?.metrics.activeEnergy ?? 0
        let calories: Int? = hkCalories ?? (metricsEnergy > 0 ? Int(metricsEnergy) : nil)

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 12) {
            metricCard(
                icon: "flame.fill",
                iconColor: .primary,
                title: "Calories Active",
                value: calories.map { "\($0)" } ?? "--",
                unit: "kcal"
            )
            metricCard(
                icon: "heart.fill",
                iconColor: .primary,
                title: "Avg HR",
                value: Int(store.summary?.metrics.averageHeartRate ?? 0).formatted(.number),
                unit: "bpm"
            )
            metricCard(
                icon: "heart.fill",
                iconColor: .primary,
                title: "Max HR",
                value: Int(store.summary?.metrics.heartRate ?? 0).formatted(.number),
                unit: "bpm"
            )
            metricCard(
                icon: "timer",
                iconColor: .primary,
                title: "Time",
                value: workout.duration.formattedDuration(),
                unit: ""
            )
        }
    }
    
    private func metricCard(icon: String, iconColor: Color, title: String, value: String, unit: String) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: icon)
                        .foregroundStyle(iconColor)
                    Text(title)
                        .font(.caption)
                        .textCase(.uppercase)
                }
                Spacer(minLength: 0)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.largeTitle.bold())
                        .foregroundStyle(.primary)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .styledGroupBox()
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - WOD Results Section

    private var wodResultsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "Results"))
                .font(.headline)
                .padding(.horizontal, 4)

            ForEach(Array(store.resultInputs.enumerated()), id: \.offset) { index, result in
                let parsed = result.parsedDescription
                GroupBox {
                    if index < store.showResults.count && store.showResults[index] {
                        VStack(spacing: 0) {
                            if !parsed.items.isEmpty {
                                Divider().padding(.leading)
                                editorRow {
                                    descriptionItems(parsed.items)
                                    Spacer()
                                }
                            }

                            if !store.resultInputs[index].exercises.isEmpty {
                                Divider().padding(.leading)
                                if index < store.exercisesEdited.count && store.exercisesEdited[index] {
                                    exerciseResultsTable(wodIndex: index)
                                } else {
                                    editExercisesButton(wodIndex: index)
                                }
                            }

                            Divider().padding(.leading)
                            if index < store.showNotes.count && store.showNotes[index] {
                                TextField(String(localized: "Add note..."), text: Binding(
                                    get: { store.resultInputs[index].note },
                                    set: { send(.updateNote(index, $0)) }
                                ), axis: .vertical)
                                .lineLimit(1...4)
                                .focused($focusedField, equals: .note(index))
                                .id(FocusField.note(index))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 10)
                            } else {
                                editorRow {
                                    Text(String(localized: "Note"))
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    addNoteButton(index: index)
                                }
                            }
                        }
                    }
                } label: {
                    VStack(spacing: 4) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(result.name)
                                .font(.subheadline)
                                .bold()
                            if let timeCap = parsed.timeCap {
                                wodTimeCapBadge(timeCap)
                            }
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { index < store.showResults.count && store.showResults[index] },
                                set: { _ in send(.toggleResult(index)) }
                            ))
                            .labelsHidden()
                        }
                        Divider()
                    }
                }
                .styledGroupBox()
            }
        }
    }

    // MARK: - WOD Score Input

    @ViewBuilder
    private func wodScoreInput(for index: Int) -> some View {
        HStack {
            Text(String(localized: "Score:"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            TextField(scorePlaceholder(for: index), text: Binding(
                get: {
                    let score = store.resultInputs[index].scoreResult
                    if case .completed = score { return "" }
                    return score.displayString
                },
                set: { send(.updateScore(index, $0)) }
            ), axis: .vertical)
            .lineLimit(1...4)
            .focused($focusedField, equals: .score(index))
            .id(FocusField.score(index))
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 10)
    }

    /// Context-aware placeholder for the score field based on WOD type.
    private func scorePlaceholder(for index: Int) -> String {
        let result = store.resultInputs[index]
        let hasStrengthSets = result.exercises.contains { $0.sets != nil }

        if hasStrengthSets {
            return String(localized: "Heaviest set (kg)")
        }

        switch result.scoreResult {
        case .amrap:   return String(localized: "Rounds + reps")
        case .forTime: return String(localized: "Time (mm:ss)")
        case .timeCap: return String(localized: "Remaining reps")
        case .forLoad: return String(localized: "Max weight (kg)")
        case .forReps: return String(localized: "Total reps")
        default:       return String(localized: "Enter score...")
        }
    }

    // MARK: - Add Note Button

    private func addNoteButton(index: Int) -> some View {
        Button {
            send(.toggleNote(index))
        } label: {
            Image(systemName: "plus.circle")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Edit Exercises Button

    private func editExercisesButton(wodIndex: Int) -> some View {
        Button {
            send(.openSetInput(wodIndex: wodIndex, exerciseIndex: 0))
        } label: {
            editorRow {
                Text(String(localized: "Log results"))
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "chevron.right.circle")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Exercise Input Row

    private func exerciseInputRow(wodIndex: Int, exerciseIndex: Int) -> some View {
        let exercise = store.resultInputs[wodIndex].exercises[exerciseIndex]

        return Button {
            send(.openSetInput(wodIndex: wodIndex, exerciseIndex: exerciseIndex))
        } label: {
            GroupBox {
                VStack(alignment: .leading, spacing: 6) {
                    exerciseHeader(exercise: exercise)

                    if let reps = exercise.plannedReps {
                        Text(String(localized: "Plan: \(reps)"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    exerciseValueSummary(exercise: exercise)
                }
            }
            .styledGroupBox()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Exercise Header

    private func exerciseHeader(exercise: ExerciseLogInput) -> some View {
        HStack {
            Text(exercise.exerciseType?.displayName ?? exercise.unmatchedName ?? String(localized: "Unknown"))
                .font(.subheadline.weight(.semibold))
            Spacer()
            if let weight = exercise.plannedWeight {
                Text("\(Int(weight)) kg")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Exercise Value Summary

    /// Shows a compact read-only summary of exercise values.
    /// Pre-filled from plan — user doesn't need to change anything unless they want to.
    @ViewBuilder
    private func exerciseValueSummary(exercise: ExerciseLogInput) -> some View {
        if let sets = exercise.sets, !sets.isEmpty {
            // Per-set: "10×40 · 10×45 · 10×50"
            if sets.contains(where: { $0.weight != nil }) {
                exerciseSetsSummary(sets: sets)
            } else {
                Text(String(localized: "No weights logged"))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        } else {
            // Simple: "21-15-9 · 43 kg"
            HStack(spacing: 4) {
                if let reps = exercise.actualReps {
                    Text(reps)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                if let weight = exercise.actualWeight {
                    Text("· \(Int(weight)) kg")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Exercise Sets (Strength)

    /// Compact read-only summary: "10×40 · 10×45 · 10×50 · 10×55 · 10×60"
    private func exerciseSetsSummary(sets: [SetEntry]) -> some View {
        let summary = sets.map { entry in
            let w = entry.weight.map { "\(Int($0))" } ?? "BW"
            return "\(entry.reps)×\(w)"
        }.joined(separator: " · ")

        return Text(summary)
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Button that opens the set input sheet.
    private func logSetsButton(wodIndex: Int, exerciseIndex: Int) -> some View {
        let hasData = store.resultInputs[wodIndex].exercises[exerciseIndex].sets?.contains { $0.weight != nil } ?? false

        return Button {
            send(.openSetInput(wodIndex: wodIndex, exerciseIndex: exerciseIndex))
        } label: {
            HStack {
                Image(systemName: hasData ? "pencil" : "plus.circle")
                Text(String(localized: hasData ? "Edit sets" : "Log sets"))
            }
            .font(.subheadline)
        }
    }

    // MARK: - Exercise Results Table (read-only markdown, after edit)

    /// Read-only markdown table showing entered exercise data. Tappable to re-edit.
    private func exerciseResultsTable(wodIndex: Int) -> some View {
        let result = store.resultInputs[wodIndex]
        return Button {
            send(.openSetInput(wodIndex: wodIndex, exerciseIndex: 0))
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                if case .completed = result.scoreResult {} else {
                    HStack {
                        Text(String(localized: "Score:"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(result.scoreResult.displayString)
                            .font(.subheadline.weight(.semibold))
                    }
                    .padding(.horizontal, 4)
                }
                StructuredText(markdown: store.resultInputs[wodIndex].exercises.markdownTable())
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Description rendering

    private func wodTimeCapBadge(_ timeCap: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "timer")
                .font(.caption2)
            Text(timeCap)
                .font(.caption2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(.secondary.opacity(0.15), in: Capsule())
        .foregroundStyle(.secondary)
    }

    private func descriptionItems(_ items: [ParsedWodDescription.Item]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(items.indices, id: \.self) { i in
                VStack(alignment: .leading, spacing: 2) {
                    Text(items[i].line)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    if let scaling = items[i].scaling {
                        Text(scaling)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func editorRow<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack { content() }
            .padding(.vertical, 10)
            .padding(.horizontal, 4)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            Button {
                send(.discardWorkoutButtonTapped)
            } label: {
                Text("Odrzuć")
                    .foregroundStyle(.red)
            }
            Spacer()
            Button {
                send(.endWorkoutButtonTapped)
            } label: {
                Text("Zapisz")
                    .fontWeight(.semibold)
            }
        }
    }
}

// MARK: - Helpers

extension TimeInterval {
    func formattedDuration() -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: self) ?? "--"
    }
}

// MARK: - Preview

#Preview("failed") {
    var state = SummaryFeature.State(viewState: .failed)
    state.summaryRetryCount = 20
    state.failureDebugInfo = "mode: watchPrimary, workout: nil, attempts: 20, metrics: WorkoutMetrics(avg: 145, hr: 0, energy: 520)"
    return SummaryView(store: Store(initialState: state) {
        SummaryFeature()
    } withDependencies: {
        $0.sessionClient.getWorkoutSummary = {
            await withCheckedContinuation { (_: CheckedContinuation<WorkoutSummary, Never>) in }
        }
    })
}

#Preview("saving") {
    SummaryView(store: Store(initialState: SummaryFeature.State(), reducer: {
        SummaryFeature()
    }))
}

#Preview("loading") {
    SummaryView(store: Store(initialState: SummaryFeature.State(viewState: .loading), reducer: {
        SummaryFeature()
    }))
}

#Preview("loaded — short") {
    let summary = WorkoutSummary.previewWorkoutSummary()
    var state = SummaryFeature.State(viewState: .successfullyLoaded)
    state.summary = summary
    return NavigationStack {
        SummaryView(store: Store(initialState: state) {
            SummaryFeature()
        } withDependencies: {
            $0.sessionClient.getWorkoutSummary = { summary }
        })
    }
}

#Preview("loaded — long (2h+)") {
    let end = Date()
    let start = end.addingTimeInterval(-7890) // 2h 11m 30s
    let workout = HKWorkout(activityType: .crossTraining, start: start, end: end)
    let summary = WorkoutSummary(
        workout: workout,
        metrics: WorkoutMetrics(averageHeartRate: 155, heartRate: 178, activeEnergy: 1240)
    )
    var state = SummaryFeature.State(viewState: .successfullyLoaded)
    state.summary = summary
    return NavigationStack {
        SummaryView(store: Store(initialState: state) {
            SummaryFeature()
        } withDependencies: {
            $0.sessionClient.getWorkoutSummary = { summary }
        })
    }
}

#Preview("Monday — AMRAP + Strength") {
    let workout = HKWorkout(activityType: .crossTraining, start: Date().addingTimeInterval(-3600), end: Date())
    let summary = WorkoutSummary(workout: workout, metrics: WorkoutMetrics(averageHeartRate: 155, heartRate: 172, activeEnergy: 580))
    var state = SummaryFeature.State(viewState: .successfullyLoaded)
    state.summary = summary
    state.resultInputs = [
        WorkoutSessionResult(
            name: "WOD",
            description: "AMRAP 25': 3 Ring Muscle-ups or 9 Pull-ups, 8 Thrusters @50/35kg, 17 Cal Row",
            scoreResult: .amrap(rounds: 6, extraReps: 14),
            exercises: [
                ExerciseLogInput(
                    exerciseType: .pullUps,
                    category: .gymnastics,
                    target: .reps(9),
                    plannedReps: "9",
                    actualReps: "9"
                ),
                ExerciseLogInput(
                    exerciseType: .thrusters,
                    category: .olympicLifting,
                    target: .reps(8),
                    plannedReps: "8",
                    plannedWeight: 50,
                    actualWeight: 50,
                    actualReps: "8"
                ),
                ExerciseLogInput(
                    exerciseType: .rowing,
                    category: .cardio,
                    target: .calories(17),
                    plannedReps: "17 cal",
                    actualReps: "17"
                ),
            ]
        ),
        WorkoutSessionResult(
            name: "Strength",
            description: "5 sets for load: 10 Close-Grip Bench Press",
            scoreResult: .forLoad(weight: 60),
            exercises: [
                ExerciseLogInput(
                    exerciseType: .benchPress,
                    category: .strength,
                    target: .reps(10),
                    plannedReps: "10-10-10-10-10",
                    sets: [
                        SetEntry(reps: 10, weight: 40),
                        SetEntry(reps: 10, weight: 45),
                        SetEntry(reps: 10, weight: 50),
                        SetEntry(reps: 10, weight: 55),
                        SetEntry(reps: 10, weight: 60),
                    ]
                ),
            ]
        ),
    ]
    state.showResults = [true, true]
    state.showNotes = [false, false]
    return NavigationStack {
        SummaryView(store: Store(initialState: state) {
            EmptyReducer()
        })
    }
}

#Preview("CrossFit — FOR TIME") {
    let workout = HKWorkout(activityType: .crossTraining, start: Date().addingTimeInterval(-2400), end: Date())
    let summary = WorkoutSummary(workout: workout, metrics: WorkoutMetrics(averageHeartRate: 165, heartRate: 178, activeEnergy: 620))
    var state = SummaryFeature.State(viewState: .successfullyLoaded)
    state.summary = summary
    state.resultInputs = [
        WorkoutSessionResult(
            name: "WOD 1",
            description: "FOR TIME TC 15': 21-15-9 Thrusters 43/30kg + Burpees + T2B",
            scoreResult: .forTime(time: 872),
            exercises: [
                ExerciseLogInput(exerciseType: .thrusters, category: .olympicLifting, plannedReps: "21-15-9", plannedWeight: 43, actualWeight: 43, actualReps: "21-15-9", isPR: true),
                ExerciseLogInput(exerciseType: .burpees, category: .mixed, plannedReps: "21-15-9", actualReps: "21-15-9"),
                ExerciseLogInput(exerciseType: .toesToBar, category: .gymnastics, plannedReps: "21-15-9", actualReps: "21-15-9"),
            ]
        ),
        WorkoutSessionResult(
            name: "WOD 2",
            description: "FOR TIME: 50 Wall Balls 9kg + 30 Box Jumps + 20 C&J 60/40kg",
            scoreResult: .timeCap(capSeconds: 900, remainingReps: 12),
            exercises: [
                ExerciseLogInput(exerciseType: .wallBalls, category: .mixed, plannedReps: "50", plannedWeight: 9, actualWeight: 9, actualReps: "50"),
                ExerciseLogInput(exerciseType: .boxJumps, category: .mixed, plannedReps: "30", actualReps: "30"),
                ExerciseLogInput(exerciseType: .cleanAndJerk, category: .olympicLifting, plannedReps: "20", plannedWeight: 60, actualWeight: 60, actualReps: "8", scaling: .rx),
            ]
        ),
    ]
    state.showResults = [true, true]
    state.showNotes = [false, false]
    return NavigationStack {
        SummaryView(store: Store(initialState: state) {
            EmptyReducer()
        })
    }
}

#Preview("CrossFit — AMRAP + EMOM") {
    let workout = HKWorkout(activityType: .crossTraining, start: Date().addingTimeInterval(-3000), end: Date())
    let summary = WorkoutSummary(workout: workout, metrics: WorkoutMetrics(averageHeartRate: 158, heartRate: 172, activeEnergy: 550))
    var state = SummaryFeature.State(viewState: .successfullyLoaded)
    state.summary = summary
    state.resultInputs = [
        WorkoutSessionResult(
            name: "EMOM 10'",
            description: "EMOM 10min: 3 Power Clean 70/50kg + 6 Push-ups",
            scoreResult: .completed,
            exercises: [
                ExerciseLogInput(exerciseType: .powerClean, category: .olympicLifting, plannedReps: "3 per min", plannedWeight: 70, actualWeight: 70, actualReps: "3 per min"),
                ExerciseLogInput(exerciseType: .pushUps, category: .gymnastics, plannedReps: "6 per min", actualReps: "6 per min"),
            ]
        ),
        WorkoutSessionResult(
            name: "WOD",
            description: "AMRAP 15': 5 HSPU, 10 KB Swing 24/16kg, 15 Cal Row",
            scoreResult: .amrap(rounds: 6, extraReps: 8),
            exercises: [
                ExerciseLogInput(exerciseType: .handstandPushUps, category: .gymnastics, plannedReps: "5", actualReps: "5"),
                ExerciseLogInput(exerciseType: .kettlebellSwing, category: .strength, plannedReps: "10", plannedWeight: 24, actualWeight: 24, actualReps: "10"),
                ExerciseLogInput(exerciseType: .rowing, category: .cardio, plannedReps: "15 cal", actualReps: "15 cal"),
            ]
        ),
    ]
    state.showResults = [true, true]
    state.showNotes = [false, false]
    return NavigationStack {
        SummaryView(store: Store(initialState: state) {
            EmptyReducer()
        })
    }
}
