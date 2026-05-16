//
//  ActivityPlanScoreView.swift
//  WorkoutMirrorLive
//

import Commons
import ComposableArchitecture
import SharedModels
import SwiftUI
import Textual

struct ActivityPlanScoreView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<ActivityPlanScoreFeature>

    // MARK: - Body

    var body: some View {
        Group {
            switch store.loadState {
            case .loading:
                loadingView
            case let .loaded(score):
                resultsView(score)
            case .notFound, .failed:
                EmptyView()
            }
        }
        .sheet(item: $store.scope(state: \.setInput, action: \.setInput)) { setInputStore in
            SetInputView(store: setInputStore)
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        GroupBox {
            loadingContent
        } label: {
            resultsLabel
        }
        .styledGroupBox()
    }

    private var loadingContent: some View {
        HStack {
            Text(String(localized: "Score:", bundle: .main))
                .font(.subheadline)
                .foregroundStyle(.primary)
            Spacer()
            ProgressView()
        }
    }

    // MARK: - Results

    private func resultsView(_ score: WorkoutPlanScore) -> some View {
        GroupBox {
            resultsList(score.results)
        } label: {
            resultsLabel
        }
        .styledGroupBox()
    }

    private func resultsList(_ results: [WorkoutSessionResult]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(results.indices, id: \.self) { index in
                if index > 0 {
                    Divider()
                }
                resultRow(results[index], wodIndex: index)
            }
        }
        .padding(.top, 4)
    }

    private func resultRow(_ result: WorkoutSessionResult, wodIndex: Int) -> some View {
        let parsed = result.parsedDescription
        return VStack(alignment: .leading, spacing: 8) {
            wodHeader(name: result.name, type: result.derivedWodType, timeCap: parsed.timeCap)
            if !parsed.items.isEmpty {
                descriptionItems(parsed.items)
            }
            if result.scoreResult != .completed {
                if !parsed.items.isEmpty {
                    Divider().padding(.vertical, 2)
                }
                resultScoreView(result.scoreResult.displayString)
            }
            if !result.note.isEmpty { captionView(result.note) }
            actualValuesTable(for: result)
            if isWodEditable(result: result) {
                editingControls(for: result, wodIndex: wodIndex)
            }
        }
    }

    /// Right-aligned controls under an editable WOD: Edit button + trailing info menu.
    private func editingControls(for result: WorkoutSessionResult, wodIndex: Int) -> some View {
        HStack(spacing: 8) {
            Spacer()
            editButton(wodIndex: wodIndex)
            infoMenu(for: result)
        }
        .padding(.top, 4)
    }

    /// Tap-to-reveal info popup showing the edit deadline as a single short line.
    /// Visual style mirrors `editButton` so the two trailing controls feel like a pair.
    private func infoMenu(for result: WorkoutSessionResult) -> some View {
        let deadline = logsFor(result: result).compactMap(\.editableUntil).min()
        let message: String = {
            guard let deadline else { return String(localized: "Edycja zablokowana") }
            return String(localized: "Edycja możliwa do \(DateTimeFormatter.numericDateTime.string(from: deadline))")
        }()
        return Menu {
            Text(message)
        } label: {
            Image(systemName: "info.circle")
                .font(.caption)
                .fontWeight(.medium)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }

    private func wodHeader(name: String, type: ExerciseWorkoutType, timeCap: String?) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(name)
                .font(.caption2.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(type.color.opacity(0.15), in: Capsule())
                .foregroundStyle(type.color)
            Spacer()
            if let timeCap {
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
        }
    }

    private func descriptionItems(_ items: [ParsedWodDescription.Item]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(items.indices, id: \.self) { index in
                VStack(alignment: .leading, spacing: 2) {
                    let split = splitPrefix(items[index].line)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        if let prefix = split.prefix {
                            Text(prefix)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Text(split.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }
                    if let scaling = items[index].scaling {
                        Text(scaling)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }

    /// Splits an exercise line like "400m Running" into ("400m", "Running").
    /// Falls back to (nil, full line) when the first word doesn't contain a digit.
    private func splitPrefix(_ line: String) -> (prefix: String?, name: String) {
        let parts = line.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        guard parts.count == 2 else { return (nil, line) }
        let first = String(parts[0])
        let rest = String(parts[1])
        if first.contains(where: \.isNumber) {
            return (first, rest)
        }
        return (nil, line)
    }

    /// Markdown table with the user's actual exercise values (reps/weight/sets).
    /// Visibility is decided per-WOD: if any exercise in the WOD carries
    /// user-entered data, render the full table for context (including prefilled
    /// exercises). If no exercise has been touched, hide the table entirely.
    @ViewBuilder
    private func actualValuesTable(for result: WorkoutSessionResult) -> some View {
        let logs = logsFor(result: result)
        if logs.contains(where: hasMeaningfulData) {
            let inputs = logs.map { ExerciseLogInput(from: $0) }
            StructuredText(markdown: inputs.markdownTable())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)
        }
    }

    /// Heuristic deciding whether a log carries data the user has actually entered
    /// (rather than the prefill copied from the plan).
    /// `Why:` SummaryFeature pre-fills `actualReps` and `sets` from the plan, so an
    /// untouched WOD still produces a log with non-nil values. Without this filter
    /// the Activity Details would always render a table, even for WODs the user
    /// never opened in Summary.
    private func hasMeaningfulData(_ log: ExerciseLog) -> Bool {
        if let sets = log.sets, sets.contains(where: { $0.weight != nil }) {
            return true
        }
        if log.actualWeight != nil {
            return true
        }
        if let actual = log.actualReps,
           let planned = log.plannedReps,
           actual != planned {
            return true
        }
        return false
    }

    /// Whether any ExerciseLog from this WOD is still inside its edit window.
    private func isWodEditable(result: WorkoutSessionResult) -> Bool {
        logsFor(result: result).contains { $0.isEditable(now: Date()) }
    }

    /// Returns logs belonging to the given `WorkoutSessionResult`.
    /// Prefers the strict UUID match on `workoutSessionResultId`; falls back to
    /// `wodName` only for legacy logs persisted before that field was introduced.
    private func logsFor(result: WorkoutSessionResult) -> [ExerciseLog] {
        store.exerciseLogs.filter { log in
            if let resultId = log.workoutSessionResultId {
                return resultId == result.id
            }
            return log.wodName == result.name
        }
    }

    private func editButton(wodIndex: Int) -> some View {
        Button {
            store.send(.editTapped(wodIndex: wodIndex))
        } label: {
            Label(String(localized: "Edytuj"), systemImage: "pencil")
                .font(.caption)
                .fontWeight(.medium)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }

    // MARK: - Result Row Components

    private func resultNameView(_ name: String) -> some View {
        Text(name)
            .font(.subheadline)
            .bold()
            .foregroundStyle(.primary)
    }

    private func captionView(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private func resultScoreView(_ score: String) -> some View {
        HStack {
            Spacer()
            Text(score)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.primary)
                .monospacedDigit()
        }
    }

    // MARK: - Shared

    private var resultsLabel: some View {
        Label(String(localized: "Results", bundle: .main), systemImage: "list.bullet.clipboard")
            .font(.caption)
            .foregroundStyle(.secondary)
    }

}

// MARK: - Preview

#Preview("loading") {
    let store = Store(
        initialState: ActivityPlanScoreFeature.State(hkWorkoutId: UUID())
    ) {
        ActivityPlanScoreFeature()
    } withDependencies: {
        $0.workoutPlanScoreClient.fetchByHKWorkoutId = { _ in
            await withCheckedContinuation { (_: CheckedContinuation<WorkoutPlanScore?, Never>) in }
        }
    }
    ActivityPlanScoreView(store: store)
        .onAppear { store.send(.fetchScore) }
        .padding()
}

#Preview("loaded") {
    let score = WorkoutPlanScore(
        trainingSessionId: UUID(),
        hkWorkoutId: UUID(),
        results: [
            WorkoutSessionResult(name: "WOD 1", description: "21-15-9 Thrusters 43kg + Pull-ups", scoreResult: .custom("14:32"), note: ""),
            WorkoutSessionResult(name: "WOD 2", description: "5x5 Back Squat", scoreResult: .forLoad(weight: 80), note: "Felt strong today")
        ]
    )
    let store = Store(
        initialState: ActivityPlanScoreFeature.State(hkWorkoutId: score.hkWorkoutId)
    ) {
        ActivityPlanScoreFeature()
    } withDependencies: {
        $0.workoutPlanScoreClient.fetchByHKWorkoutId = { _ in score }
    }
    ActivityPlanScoreView(store: store)
        .onAppear { store.send(.fetchScore) }
        .padding()
}

#Preview("notFound") {
    let store = Store(
        initialState: ActivityPlanScoreFeature.State(hkWorkoutId: UUID())
    ) {
        ActivityPlanScoreFeature()
    } withDependencies: {
        $0.workoutPlanScoreClient.fetchByHKWorkoutId = { _ in nil }
    }
    ActivityPlanScoreView(store: store)
        .onAppear { store.send(.fetchScore) }
        .padding()
}

#Preview("failed") {
    let store = Store(
        initialState: ActivityPlanScoreFeature.State(hkWorkoutId: UUID())
    ) {
        ActivityPlanScoreFeature()
    } withDependencies: {
        $0.workoutPlanScoreClient.fetchByHKWorkoutId = { _ in throw URLError(.unknown) }
    }
    ActivityPlanScoreView(store: store)
        .onAppear { store.send(.fetchScore) }
        .padding()
}
