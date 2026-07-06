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
    
    // MARK: - Loading States

    // `loadingView` / `failedView` wydzielone do `SummaryView+LoadingStates.swift`

    // MARK: - Summary
    
    @ViewBuilder
    private var summaryView: some View {
        summaryContent
            .background(summaryBackground)
            .navigationTitle(String(localized: "Summary"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .alert(store: store.scope(state: \.$discardAlert, action: \.alert))
            .alert(store: store.scope(state: \.$errorAlert, action: \.errorAlert))
            .sheet(item: $store.scope(state: \.setInput, action: \.setInput)) { store in
                SetInputView(store: store)
            }
            // Block all interactions (Save/End, edit fields, toolbar) during the
            // ~delete operation. Alerts remain interactive (presented above this layer).
            .disabled(store.isDiscarding)
    }

    private var summaryContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 12) {
                    if let workout = store.summary?.workout {
                        headerCard(workout: workout)
                        metricsGrid(workout: workout)
                    }
                    if !store.wodScorings.isEmpty {
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
    }

    private var summaryBackground: some View {
        LinearGradient(
            colors: [Color.gray.opacity(0.2), .clear],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
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
        LazyVGrid(columns: twoColumnGrid, alignment: .leading, spacing: 12) {
            caloriesCard(workout: workout)
            avgHRCard
            maxHRCard
            timeCard(workout: workout)
        }
    }

    private var twoColumnGrid: [GridItem] {
        [GridItem(.flexible()), GridItem(.flexible())]
    }

    private func caloriesCard(workout: HKWorkout) -> some View {
        let hkCalories = workout.statistics(for: .init(.activeEnergyBurned))?
            .sumQuantity()
            .map { Int($0.doubleValue(for: .kilocalorie())) }
        let metricsEnergy = store.summary?.metrics.activeEnergy ?? 0
        let calories: Int? = hkCalories ?? (metricsEnergy > 0 ? Int(metricsEnergy) : nil)

        return metricCard(
            icon: "flame.fill",
            iconColor: .primary,
            title: String(localized: "Calories Active"),
            value: calories.map { "\($0)" } ?? "--",
            unit: "kcal"
        )
    }

    private var avgHRCard: some View {
        metricCard(
            icon: "heart.fill",
            iconColor: .primary,
            title: String(localized: "Avg HR"),
            value: Int(store.summary?.metrics.averageHeartRate ?? 0).formatted(.number),
            unit: "bpm"
        )
    }

    private var maxHRCard: some View {
        metricCard(
            icon: "heart.fill",
            iconColor: .primary,
            title: String(localized: "Max HR"),
            value: Int(store.summary?.metrics.heartRate ?? 0).formatted(.number),
            unit: "bpm"
        )
    }

    private func timeCard(workout: HKWorkout) -> some View {
        metricCard(
            icon: "timer",
            iconColor: .primary,
            title: String(localized: "Time"),
            value: workout.duration.formattedDuration(),
            unit: ""
        )
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
            resultsHeader
            ForEach(store.wodScorings) { scoring in
                resultCard(at: scoring.wodIndex, result: scoring.result)
            }
        }
    }

    private var resultsHeader: some View {
        Text(String(localized: "Results"))
            .font(.headline)
            .padding(.horizontal, 4)
    }

    private func resultCard(at index: Int, result: WorkoutSessionResult) -> some View {
        let parsed = result.parsedDescription
        return GroupBox {
            resultCardContent(at: index, parsed: parsed)
        } label: {
            resultCardLabel(at: index, result: result, parsed: parsed)
        }
        .styledGroupBox()
    }

    @ViewBuilder
    private func resultCardContent(at index: Int, parsed: ParsedWodDescription) -> some View {
        if store.wodScorings[id: index]?.showResults == true {
            VStack(spacing: 0) {
                resultDescriptionSection(parsed: parsed)
                resultExercisesSection(at: index)
                resultNoteSection(at: index)
            }
        }
    }

    @ViewBuilder
    private func resultDescriptionSection(parsed: ParsedWodDescription) -> some View {
        if !parsed.items.isEmpty {
            Divider().padding(.leading)
            editorRow {
                descriptionItems(parsed.items)
                Spacer()
            }
        }
    }

    @ViewBuilder
    private func resultExercisesSection(at index: Int) -> some View {
        if let scoring = store.wodScorings[id: index], !scoring.result.exercises.isEmpty {
            Divider().padding(.leading)
            if scoring.exercisesEdited {
                exerciseResultsTable(wodIndex: index)
            } else {
                editExercisesButton(wodIndex: index)
            }
        }
    }

    @ViewBuilder
    private func resultNoteSection(at index: Int) -> some View {
        Divider().padding(.leading)
        if store.wodScorings[id: index]?.showNotes == true {
            resultNoteTextField(at: index)
        } else {
            editorRow {
                Text(String(localized: "Note"))
                    .foregroundStyle(.secondary)
                Spacer()
                addNoteButton(index: index)
            }
        }
    }

    private func resultNoteTextField(at index: Int) -> some View {
        TextField(String(localized: "Add note..."), text: Binding(
            get: { store.wodScorings[id: index]?.result.note ?? "" },
            set: { send(.updateNote(index, $0)) }
        ), axis: .vertical)
        .lineLimit(1...4)
        .focused($focusedField, equals: .note(index))
        .id(FocusField.note(index))
        .padding(.horizontal, 4)
        .padding(.vertical, 10)
    }

    private func resultCardLabel(at index: Int, result: WorkoutSessionResult, parsed: ParsedWodDescription) -> some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(result.name)
                    .font(.subheadline)
                    .bold()
                if let timeCap = parsed.timeCap {
                    wodTimeCapBadge(timeCap)
                }
                Spacer()
                resultToggle(at: index)
            }
            Divider()
        }
    }

    private func resultToggle(at index: Int) -> some View {
        Toggle("", isOn: Binding(
            get: { store.wodScorings[id: index]?.showResults ?? false },
            set: { _ in send(.toggleResult(index)) }
        ))
        .labelsHidden()
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
                    guard let score = store.wodScorings[id: index]?.result.scoreResult else { return "" }
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
        guard let result = store.wodScorings[id: index]?.result else { return "" }
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

    @ViewBuilder
    private func exerciseInputRow(wodIndex: Int, exerciseIndex: Int) -> some View {
        if let scoring = store.wodScorings[id: wodIndex],
           exerciseIndex < scoring.result.exercises.count {
            let exercise = scoring.result.exercises[exerciseIndex]
            Button {
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
    }

    // MARK: - Exercise Header

    private func exerciseHeader(exercise: ExerciseLogInput) -> some View {
        HStack {
            exerciseHeaderName(exercise)
            Spacer()
            exerciseHeaderPlannedWeight(exercise)
        }
    }

    private func exerciseHeaderName(_ exercise: ExerciseLogInput) -> some View {
        Text(exercise.exerciseType?.displayName ?? exercise.unmatchedName ?? String(localized: "Unknown"))
            .font(.subheadline.weight(.semibold))
    }

    @ViewBuilder
    private func exerciseHeaderPlannedWeight(_ exercise: ExerciseLogInput) -> some View {
        if let weight = exercise.plannedWeight {
            Text("\(Int(weight)) kg")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Exercise Value Summary

    /// Shows a compact read-only summary of exercise values.
    /// Pre-filled from plan — user doesn't need to change anything unless they want to.
    @ViewBuilder
    private func exerciseValueSummary(exercise: ExerciseLogInput) -> some View {
        if let sets = exercise.sets, !sets.isEmpty {
            exerciseValueSetSummary(sets: sets)
        } else {
            exerciseValueSimpleSummary(exercise: exercise)
        }
    }

    @ViewBuilder
    private func exerciseValueSetSummary(sets: [SetEntry]) -> some View {
        if sets.contains(where: { $0.weight != nil }) {
            exerciseSetsSummary(sets: sets)
        } else {
            exerciseValueNoWeightsText
        }
    }

    private var exerciseValueNoWeightsText: some View {
        Text(String(localized: "No weights logged"))
            .font(.caption)
            .foregroundStyle(.tertiary)
    }

    private func exerciseValueSimpleSummary(exercise: ExerciseLogInput) -> some View {
        HStack(spacing: 4) {
            exerciseValueRepsText(exercise.actualReps)
            exerciseValueWeightText(exercise.actualWeight)
        }
    }

    @ViewBuilder
    private func exerciseValueRepsText(_ reps: String?) -> some View {
        if let reps {
            Text(reps)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func exerciseValueWeightText(_ weight: Double?) -> some View {
        if let weight {
            Text("· \(Int(weight)) kg")
                .font(.caption)
                .foregroundStyle(.secondary)
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
        let exercises = store.wodScorings[id: wodIndex]?.result.exercises ?? []
        let hasData = exerciseIndex < exercises.count
            && (exercises[exerciseIndex].sets?.contains { $0.weight != nil } ?? false)

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
    @ViewBuilder
    private func exerciseResultsTable(wodIndex: Int) -> some View {
        if let result = store.wodScorings[id: wodIndex]?.result {
            Button {
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
                    StructuredText(markdown: result.exercises.markdownTable())
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
        }
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
            ForEach(items.indices, id: \.self) { index in
                VStack(alignment: .leading, spacing: 2) {
                    Text(items[index].line)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    if let scaling = items[index].scaling {
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

    // `toolbarContent` + buttons (cancel/discard/save) wydzielone do `SummaryView+Toolbar.swift`
}

