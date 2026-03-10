//
//  ActivityPlanScoreView.swift
//  WorkoutMirrorLive
//

import ComposableArchitecture
import SharedModels
import SwiftUI

struct ActivityPlanScoreView: View {

    // MARK: - Properties

    let store: StoreOf<ActivityPlanScoreFeature>

    // MARK: - Body

    var body: some View {
        switch store.loadState {
        case .loading:
            loadingView
        case let .loaded(score):
            resultsView(score)
        case .notFound, .failed:
            EmptyView()
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
                resultRow(results[index])
            }
        }
        .padding(.top, 4)
    }

    private func resultRow(_ result: WorkoutSessionResult) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            resultNameView(result.name)
            if !result.description.isEmpty { captionView(result.description) }
            if !result.score.isEmpty { resultScoreView(result.score) }
            if !result.note.isEmpty { captionView(result.note) }
        }
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
            Text(String(localized: "Score:", bundle: .main))
                .font(.subheadline)
                .foregroundStyle(.primary)
            Spacer()
            Text(score)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
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
            WorkoutSessionResult(name: "WOD 1", description: "21-15-9 Thrusters 43kg + Pull-ups", score: "14:32", note: ""),
            WorkoutSessionResult(name: "WOD 2", description: "5x5 Back Squat", score: "80kg", note: "Felt strong today")
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
