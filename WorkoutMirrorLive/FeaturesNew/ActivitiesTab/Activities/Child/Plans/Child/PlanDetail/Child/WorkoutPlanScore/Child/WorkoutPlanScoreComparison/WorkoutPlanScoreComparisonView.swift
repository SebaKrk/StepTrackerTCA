//
//  WorkoutPlanScoreComparisonView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 08/03/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

@ViewAction(for: WorkoutPlanScoreComparisonFeature.self)
struct WorkoutPlanScoreComparisonView: View {

    // MARK: - Properties

    let store: StoreOf<WorkoutPlanScoreComparisonFeature>

    // MARK: - Body

    var body: some View {
        ContentUnavailableView(
            "Comparison coming soon",
            systemImage: "chart.line.uptrend.xyaxis",
            description: Text("Charts comparing your selected workouts will appear here.")
        )
        .navigationTitle(String(localized: "Compare"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { send(.viewDidAppear) }
    }
}

// MARK: - Preview

#Preview {
    let session = TrainingSession.previewTrainingSession
    let scores: [WorkoutPlanScore] = [
        WorkoutPlanScore(
            date: Date().addingTimeInterval(-86400 * 7),
            trainingSessionId: session.id,
            hkWorkoutId: UUID(),
            results: [
                WorkoutSessionResult(name: "Weightlifting - Clean and Jerk", description: "", score: "80kg", note: ""),
                WorkoutSessionResult(name: "WOD 1", description: "", score: "11:43", note: "")
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
        WorkoutPlanScoreComparisonView(
            store: Store(initialState: WorkoutPlanScoreComparisonFeature.State(scores: scores)) {
                WorkoutPlanScoreComparisonFeature()
            }
        )
    }
}
