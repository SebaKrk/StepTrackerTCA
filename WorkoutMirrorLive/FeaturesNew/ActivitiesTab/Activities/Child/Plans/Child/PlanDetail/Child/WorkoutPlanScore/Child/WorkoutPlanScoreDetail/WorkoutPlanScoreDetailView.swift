//
//  WorkoutPlanScoreDetailView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 08/03/2026.
//

import ComposableArchitecture
import HealthHub
import SharedModels
import SwiftUI

@ViewAction(for: WorkoutPlanScoreDetailFeature.self)
struct WorkoutPlanScoreDetailView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<WorkoutPlanScoreDetailFeature>

    @Shared(.inMemory(.readinessLevelColor)) var color: Color = .gray

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                wodResultsSection
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
        }
        .contentMargins(.bottom, 40, for: .scrollContent)
        .background(
            LinearGradient(
                colors: [color.opacity(0.2), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle(store.score.date.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    send(.viewActivityTapped)
                } label: {
                    if store.isLoadingActivity {
                        ProgressView()
                    } else {
                        Label("Activity", systemImage: "figure.run")
                    }
                }
                .disabled(store.isLoadingActivity)
            }
        }
        .fullScreenCover(
            item: $store.scope(state: \.destination?.activityDetails, action: \.destination.activityDetails)
        ) { activityStore in
            NavigationStack {
                ActivityDetailsView(store: activityStore)
            }
        }
    }

    // MARK: - WOD Results

    private var wodResultsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "Results"))
                .font(.headline)
                .padding(.horizontal, 4)

            ForEach(store.score.results) { result in
                GroupBox {
                    VStack(alignment: .leading, spacing: 6) {
                        if !result.description.isEmpty {
                            Text(result.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Divider()
                        }
                        if result.scoreResult != .completed {
                            HStack {
                                Text(String(localized: "Score"))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(result.scoreResult.displayString)
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
                scoreResult: $0.name == "WOD 1" ? .custom("11:43") : .forLoad(weight: 80),
                note: $0.name == "WOD 1" ? "ciężkie, ale dałem radę" : ""
            )
        }
    )
    return NavigationStack {
        WorkoutPlanScoreDetailView(
            store: Store(initialState: WorkoutPlanScoreDetailFeature.State(score: score)) {
                WorkoutPlanScoreDetailFeature()
            } withDependencies: {
                $0.activityClient.fetchWorkoutById = { _ in nil }
                $0.maxHeartRateClient.forWorkout = { _ in 190 }
            }
        )
    }
}
