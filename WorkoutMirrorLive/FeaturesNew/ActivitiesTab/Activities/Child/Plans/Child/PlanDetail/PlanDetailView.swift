//
//  PlanDetailView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 12/02/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

@ViewAction(for: PlanDetailFeature.self)
struct PlanDetailView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<PlanDetailFeature>

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                workoutContent
                scoreSection
            }
        }
        .contentMargins(.bottom, 40, for: .scrollContent)
        .background(
            LinearGradient(
                colors: [store.color.opacity(0.25), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle(store.trainingSession.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .onAppear { send(.viewDidAppear) }
        .navigationDestination(
            item: $store.scope(state: \.destination?.editor, action: \.destination.editor)
        ) { editorStore in
            TrainingSessionEditorView(store: editorStore)
        }
        .navigationDestination(
            item: $store.scope(state: \.destination?.history, action: \.destination.history)
        ) { historyStore in
            WorkoutPlanScoreListView(store: historyStore)
        }
    }

    // MARK: - Workout Content

    private var workoutContent: some View {
        WorkoutDetailContent(
            session: store.trainingSession,
            isWarmupExpanded: Binding(
                get: { store.isWarmupExpanded },
                set: { _ in send(.warmupToggleTapped) }
            ),
            isCooldownExpanded: Binding(
                get: { store.isCooldownExpanded },
                set: { _ in send(.cooldownToggleTapped) }
            )
        )
        .padding()
    }

    // MARK: - Score Section

    private var scoreSection: some View {
        WorkoutPlanScoreView(
            store: store.scope(state: \.scoreLoader, action: \.scoreLoader),
            onHistoryTapped: { send(.historyTapped) }
        )
        .padding(.horizontal)
        .padding(.bottom)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                send(.doneTapped)
            } label: {
                Text("Done").fontWeight(.semibold)
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                send(.editTapped)
            } label: {
                Text("Edit")
            }
        }
        ToolbarItemGroup(placement: .bottomBar) {
            Spacer()
            Button {
                send(.startWorkoutTapped)
            } label: {
                Label(String(localized: "Start Workout"), systemImage: "play.fill")
                    .fontWeight(.semibold)
            }
        }
    }
}

// MARK: - Preview

#Preview("no history") {
    let session = TrainingSession.previewTrainingSession
    return NavigationStack {
        PlanDetailView(store: Store(initialState: PlanDetailFeature.State(trainingSession: session)) {
            PlanDetailFeature()
        } withDependencies: {
            $0.workoutPlanScoreClient.fetchByTrainingSessionId = { _ in [] }
        })
    }
}

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
    var state = PlanDetailFeature.State(trainingSession: session)
    state.scoreLoader.loadState = .loaded(history)
    return NavigationStack {
        PlanDetailView(store: Store(initialState: state) {
            PlanDetailFeature()
        } withDependencies: {
            $0.workoutPlanScoreClient.fetchByTrainingSessionId = { _ in history }
            $0.dismiss = .init { }
        })
    }
}
