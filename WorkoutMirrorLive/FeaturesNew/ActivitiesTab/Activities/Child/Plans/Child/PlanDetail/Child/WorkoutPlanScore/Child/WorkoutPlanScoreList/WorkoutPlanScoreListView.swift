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

    // MARK: - Score List

    private func scoreList(_ scores: [WorkoutPlanScore]) -> some View {
        List(selection: $selection) {
            ForEach(scores) { score in
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
        }
        .environment(\.editMode, $editMode)
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
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
            ToolbarItemGroup(placement: .bottomBar) {
                if editMode.isEditing, selection.count >= 2 {
                    Spacer()
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
            }
        }
    }

    // MARK: - Score Card

    private func scoreCard(score: WorkoutPlanScore) -> some View {
        GroupBox {
            resultsPreview(score.results)
        } label: {
            HStack {
                Text(score.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                if !editMode.isEditing {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .styledGroupBox()
        .padding(4)
    }

    // MARK: - Results Preview

    private func resultsPreview(_ results: [WorkoutSessionResult]) -> some View {
        let visible = results.filter { !$0.score.isEmpty }.prefix(3)

        return VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(visible.enumerated()), id: \.offset) { _, result in
                HStack {
                    Text(result.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer()
                    Text(result.score)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }
            if results.filter({ !$0.score.isEmpty }).count > 3 {
                Text("+ \(results.filter({ !$0.score.isEmpty }).count - 3) more")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Empty / Failed

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
            Button {
                send(.retryTapped)
            } label: {
                Text("Retry")
            }
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
                WorkoutSessionResult(name: "Weightlifting - Clean and Jerk", description: "", score: "80kg", note: ""),
                WorkoutSessionResult(name: "WOD 1", description: "", score: "11:43", note: "ciężkie")
            ]
        ),
        WorkoutPlanScore(
            date: Date().addingTimeInterval(-86400 * 14),
            trainingSessionId: session.id,
            hkWorkoutId: UUID(),
            results: [
                WorkoutSessionResult(name: "Weightlifting - Clean and Jerk", description: "", score: "75kg", note: ""),
                WorkoutSessionResult(name: "WOD 1", description: "", score: "13:21", note: "")
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
