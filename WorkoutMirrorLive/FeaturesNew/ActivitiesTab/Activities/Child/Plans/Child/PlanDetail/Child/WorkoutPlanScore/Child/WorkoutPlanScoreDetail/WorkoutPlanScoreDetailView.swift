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
        .background(backgroundGradient)
        .navigationTitle(navigationTitleText)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .fullScreenCover(
            item: $store.scope(state: \.destination?.activityDetails, action: \.destination.activityDetails)
        ) { activityStore in
            activityDetailsCover(activityStore)
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

    private var navigationTitleText: String {
        store.score.date.formatted(date: .abbreviated, time: .omitted)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            activityToolbarButton
        }
    }

    private func activityDetailsCover(_ store: StoreOf<ActivityDetailsFeature>) -> some View {
        NavigationStack {
            ActivityDetailsView(store: store)
        }
    }

    private var wodResultsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            resultsHeader
            ForEach(store.score.results) { result in
                resultCard(result)
            }
        }
    }

    private func resultCard(_ result: WorkoutSessionResult) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 6) {
                resultDescription(result.description)
                resultScore(result)
                resultNote(result.note)
            }
        } label: {
            resultCardLabel(result.name)
        }
        .styledGroupBox()
    }

    // MARK: - Atomic SubViews

    private var resultsHeader: some View {
        Text(String(localized: "Results"))
            .font(.headline)
            .padding(.horizontal, 4)
    }

    private var activityToolbarButton: some View {
        Button {
            send(.viewActivityTapped)
        } label: {
            activityToolbarLabel
        }
        .disabled(store.isLoadingActivity)
    }

    @ViewBuilder
    private var activityToolbarLabel: some View {
        if store.isLoadingActivity {
            ProgressView()
        } else {
            Label("Activity", systemImage: "figure.run")
        }
    }

    @ViewBuilder
    private func resultDescription(_ description: String) -> some View {
        if !description.isEmpty {
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
            Divider()
        }
    }

    @ViewBuilder
    private func resultScore(_ result: WorkoutSessionResult) -> some View {
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
    }

    @ViewBuilder
    private func resultNote(_ note: String) -> some View {
        if !note.isEmpty {
            Divider()
            Text(note)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func resultCardLabel(_ name: String) -> some View {
        Text(name)
            .font(.subheadline)
            .bold()
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
