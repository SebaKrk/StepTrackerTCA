//
//  WorkoutPlanScoreDetailView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 08/03/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

struct WorkoutPlanScoreDetailView: View {

    // MARK: - Properties

    let store: StoreOf<WorkoutPlanScoreDetailFeature>

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // TODO: IOS-00070-F — metryki zdrowotne (kalorie, HR avg, HR max, czas)
                // fetchByHKWorkoutId(score.hkWorkoutId) → HKWorkout → metricsGrid

                wodResultsSection
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
        }
        .contentMargins(.bottom, 40, for: .scrollContent)
        .navigationTitle(store.score.date.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - WOD Results

    private var wodResultsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "Results"))
                .font(.headline)
                .padding(.horizontal, 4)

            ForEach(store.score.results, id: \.name) { result in
                GroupBox {
                    VStack(alignment: .leading, spacing: 6) {
                        if !result.description.isEmpty {
                            Text(result.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Divider()
                        }
                        if !result.score.isEmpty {
                            HStack {
                                Text(String(localized: "Score"))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(result.score)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }
                        if !result.note.isEmpty {
                            Divider()
                            Text(result.note)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } label: {
                    Text(result.name)
                        .font(.subheadline)
                        .bold()
                }
                .styledGroupBox()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let session = TrainingSession.previewTrainingSession
    let score = WorkoutPlanScore(
        date: Date().addingTimeInterval(-86400 * 7),
        trainingSessionId: session.id,
        hkWorkoutId: UUID(),
        results: session.workouts.map {
            WorkoutSessionResult(
                name: $0.name,
                description: $0.snapshotDescription,
                score: $0.name == "WOD 1" ? "11:43" : "80kg",
                note: $0.name == "WOD 1" ? "ciężkie, ale dałem radę" : ""
            )
        }
    )
    return NavigationStack {
        WorkoutPlanScoreDetailView(
            store: Store(initialState: WorkoutPlanScoreDetailFeature.State(score: score)) {
                WorkoutPlanScoreDetailFeature()
            }
        )
    }
}
