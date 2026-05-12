//
//  WorkoutPlanScoreListView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 08/03/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

@ViewAction(for: WorkoutPlanScoreListFeature.self)
struct WorkoutPlanScoreListView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<WorkoutPlanScoreListFeature>

    @Shared(.inMemory(.readinessLevelColor)) var color: Color = .gray

    @State private var editMode: EditMode = .inactive
    @State private var selection: Set<WorkoutPlanScore.ID> = []

    // MARK: - Body

    var body: some View {
        Group {
            switch store.scoreLoader.loadState {
            case .loading:
                ProgressView()
            case .loaded(let scores) where scores.isEmpty:
                emptyView
            case .loaded(let scores):
                scoreList(scores)
            case .failed:
                failedView
            }
        }
        .navigationTitle(String(localized: "History"))
        .navigationBarTitleDisplayMode(.inline)
        .background(backgroundGradient)
        .onAppear { send(.viewDidAppear) }
        .navigationDestination(
            item: $store.scope(state: \.destination?.detail, action: \.destination.detail)
        ) { detailStore in
            WorkoutPlanScoreDetailView(store: detailStore)
        }
        .navigationDestination(
            item: $store.scope(state: \.destination?.comparison, action: \.destination.comparison)
        ) { comparisonStore in
            WorkoutPlanScoreComparisonView(store: comparisonStore)
        }
    }

    // MARK: - Composite SubViews

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [color.opacity(0.2), .clear],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private func scoreList(_ scores: [WorkoutPlanScore]) -> some View {
        List(selection: $selection) {
            ForEach(scores) { score in
                scoreListRow(score)
            }
        }
        .environment(\.editMode, $editMode)
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .toolbar { scoreListToolbar }
    }

    private func scoreListRow(_ score: WorkoutPlanScore) -> some View {
        scoreCard(score: score)
            .contentShape(Rectangle())
            .onTapGesture {
                guard !editMode.isEditing else { return }
                send(.scoreTapped(score))
            }
            .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }

    private func scoreCard(score: WorkoutPlanScore) -> some View {
        GroupBox {
            resultsPreview(score.results)
        } label: {
            scoreCardLabel(date: score.date)
        }
        .styledGroupBox()
        .padding(4)
    }

    private func scoreCardLabel(date: Date) -> some View {
        HStack {
            scoreCardDateText(date)
            Spacer()
            if !editMode.isEditing {
                scoreCardChevron
            }
        }
    }

    private func resultsPreview(_ results: [WorkoutSessionResult]) -> some View {
        let scored = results.filter { $0.scoreResult != .completed }
        let visible = scored.prefix(3)
        let extraCount = scored.count - visible.count

        return VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(visible.enumerated()), id: \.offset) { _, result in
                resultPreviewRow(result)
            }
            if extraCount > 0 {
                resultPreviewMoreText(extraCount)
            }
        }
    }

    private var emptyView: some View {
        ContentUnavailableView(
            String(localized: "No workouts yet"),
            systemImage: "clock.arrow.circlepath",
            description: Text("Your completed workouts will appear here.")
        )
    }

    private var failedView: some View {
        ContentUnavailableView {
            Label(
                String(localized: "Could not load history"),
                systemImage: "exclamationmark.triangle"
            )
        } description: {
            Text("Something went wrong while loading your workout history.")
        } actions: {
            retryButton
        }
    }

    @ToolbarContentBuilder
    private var scoreListToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            selectButton
        }
        ToolbarItemGroup(placement: .bottomBar) {
            if editMode.isEditing, selection.count >= 2 {
                Spacer()
                compareButton
            }
        }
    }

    // MARK: - Atomic SubViews

    private func scoreCardDateText(_ date: Date) -> some View {
        Text(date.formatted(date: .abbreviated, time: .omitted))
            .font(.headline)
            .foregroundColor(.primary)
    }

    private var scoreCardChevron: some View {
        Image(systemName: "chevron.right")
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private func resultPreviewRow(_ result: WorkoutSessionResult) -> some View {
        HStack {
            Text(result.name)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer()
            Text(result.scoreResult.displayString)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
    }

    private func resultPreviewMoreText(_ count: Int) -> some View {
        Text("+ \(count) more")
            .font(.caption2)
            .foregroundStyle(.tertiary)
    }

    private var selectButton: some View {
        Button {
            withAnimation {
                editMode = editMode.isEditing ? .inactive : .active
                if !editMode.isEditing { selection = [] }
            }
        } label: {
            Text(editMode.isEditing ? String(localized: "Done") : String(localized: "Select"))
                .fontWeight(editMode.isEditing ? .semibold : .regular)
        }
    }

    private var compareButton: some View {
        Button {
            let selected = store.scoreLoader.scores.filter { selection.contains($0.id) }
            send(.compareTapped(selected))
            selection = []
            editMode = .inactive
        } label: {
            Label(String(localized: "Compare"), systemImage: "chart.line.uptrend.xyaxis")
                .fontWeight(.semibold)
        }
    }

    private var retryButton: some View {
        Button {
            send(.retryTapped)
        } label: {
            Text(String(localized: "Retry"))
        }
    }
}

// MARK: - Preview

#Preview("with history") {
    let session = TrainingSession.previewTrainingSession
    let history: [WorkoutPlanScore] = [
        WorkoutPlanScore(
            date: Date().addingTimeInterval(-86400 * 7),
            trainingSessionId: session.id,
            hkWorkoutId: UUID(),
            results: [
                WorkoutSessionResult(name: "Weightlifting - Clean and Jerk", description: "", scoreResult: .forLoad(weight: 80), note: ""),
                WorkoutSessionResult(name: "WOD 1", description: "", scoreResult: .custom("11:43"), note: "ciężkie")
            ]
        ),
        WorkoutPlanScore(
            date: Date().addingTimeInterval(-86400 * 14),
            trainingSessionId: session.id,
            hkWorkoutId: UUID(),
            results: [
                WorkoutSessionResult(name: "Weightlifting - Clean and Jerk", description: "", scoreResult: .forLoad(weight: 75), note: ""),
                WorkoutSessionResult(name: "WOD 1", description: "", scoreResult: .custom("13:21"), note: "")
            ]
        )
    ]
    return NavigationStack {
        WorkoutPlanScoreListView(store: Store(initialState: WorkoutPlanScoreListFeature.State(trainingSession: session)) {
            WorkoutPlanScoreListFeature()
        } withDependencies: {
            $0.workoutPlanScoreClient.fetchByTrainingSessionId = { _ in history }
        })
    }
}

#Preview("empty") {
    let session = TrainingSession.previewTrainingSession
    return NavigationStack {
        WorkoutPlanScoreListView(store: Store(initialState: WorkoutPlanScoreListFeature.State(trainingSession: session)) {
            WorkoutPlanScoreListFeature()
        } withDependencies: {
            $0.workoutPlanScoreClient.fetchByTrainingSessionId = { _ in [] }
        })
    }
}

#Preview("failed") {
    let session = TrainingSession.previewTrainingSession
    var state = WorkoutPlanScoreListFeature.State(trainingSession: session)
    state.scoreLoader.loadState = .failed
    return NavigationStack {
        WorkoutPlanScoreListView(store: Store(initialState: state) {
            WorkoutPlanScoreListFeature()
        } withDependencies: {
            $0.workoutPlanScoreClient.fetchByTrainingSessionId = { _ in
                throw URLError(.notConnectedToInternet)
            }
        })
    }
}
