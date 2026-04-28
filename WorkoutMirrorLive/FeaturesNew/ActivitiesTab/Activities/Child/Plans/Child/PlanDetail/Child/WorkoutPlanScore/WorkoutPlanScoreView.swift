//
//  WorkoutPlanScoreView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 08/03/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

/// A reusable view that displays the workout score history section.
///
/// Shows a loading indicator while fetching, a tappable summary button
/// when scores are available, and nothing when empty or failed.
/// Embed this view wherever `WorkoutPlanScoreFeature` is used.
struct WorkoutPlanScoreView: View {

    // MARK: - Properties

    let store: StoreOf<WorkoutPlanScoreFeature>
    let onHistoryTapped: () -> Void

    // MARK: - Body

    var body: some View {
        switch store.loadState {
        case .loading:
            loadingView

        case .loaded(let scores) where !scores.isEmpty:
            historyButton(count: scores.count)

        case .loaded, .failed:
            EmptyView()
        }
    }

    // MARK: - SubView
    
    private var loadingView: some View {
        GroupBox {
            HStack {
                Text(String(localized: "History"))
                Spacer()
                ProgressView()
            }
        }
        .styledGroupBox()
    }

    private func historyButton(count: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                onHistoryTapped()
            } label: {
                historyButtonRow(count: count)
            }
            .buttonStyle(.plain)

            historyDescription
        }
    }

    private func historyButtonRow(count: Int) -> some View {
        GroupBox {
            HStack {
                Text(String(localized: "History"))
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(count)")
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .styledGroupBox()
    }

    private var historyDescription: some View {
        Text(String(localized: "Your past results for this plan — track your progress over time."))
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
    }
}

// MARK: - Preview

#Preview("loading") {
    WorkoutPlanScoreView(
        store: Store(initialState: WorkoutPlanScoreFeature.State(trainingSessionId: UUID())) {
            WorkoutPlanScoreFeature()
        } withDependencies: {
            $0.workoutPlanScoreClient.fetchByTrainingSessionId = { _ in
                try await Task.sleep(for: .seconds(999))
                return []
            }
        },
        onHistoryTapped: {}
    )
    .padding()
}

#Preview("loaded") {
    let session = TrainingSession.previewTrainingSession
    let scores: [WorkoutPlanScore] = [
        WorkoutPlanScore(
            date: Date().addingTimeInterval(-86400 * 7),
            trainingSessionId: session.id,
            hkWorkoutId: UUID(),
            results: [
                WorkoutSessionResult(name: "Weightlifting - Clean and Jerk", description: "", scoreResult: .forLoad(weight: 80), note: ""),
                WorkoutSessionResult(name: "WOD 1", description: "", scoreResult: .custom("11:43"), note: "")
            ]
        )
    ]
    var state = WorkoutPlanScoreFeature.State(trainingSessionId: session.id)
    state.loadState = .loaded(scores)
    return WorkoutPlanScoreView(
        store: Store(initialState: state) {
            WorkoutPlanScoreFeature()
        },
        onHistoryTapped: {}
    )
    .padding()
}

#Preview("failed") {
    var state = WorkoutPlanScoreFeature.State(trainingSessionId: UUID())
    state.loadState = .failed
    return WorkoutPlanScoreView(
        store: Store(initialState: state) {
            WorkoutPlanScoreFeature()
        },
        onHistoryTapped: {}
    )
    .padding()
}
