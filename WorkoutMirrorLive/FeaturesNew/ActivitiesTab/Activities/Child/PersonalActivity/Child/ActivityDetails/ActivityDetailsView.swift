//
//  ActivityDetailsView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 26/12/2025.
//

import ComposableArchitecture
import SwiftUI
import SharedModels
import HealthHub
import HealthKit

@ViewAction(for: ActivityDetailsFeature.self)
struct ActivityDetailsView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<ActivityDetailsFeature>
    
    // MARK: - Body
    
    var body: some View {
        rootView
            .padding([.leading, .trailing], 8)
            .navigationTitle(navigationTitleText)
            .background(LinearGradient(colors: [store.color.opacity(0.25), .clear], startPoint: .topLeading, endPoint: .bottomTrailing))
            .toolbar { linkTemplateToolbarItem }
            .onAppear {
                send(.viewDidAppear)
            }
            .navigationDestination(
                item: $store.scope(
                    state: \.destination?.metricDetail,
                    action: \.destination.metricDetail)) { store in
                        MetricDetailView(store: store)
                    }
            .sheet(
                item: $store.scope(
                    state: \.destination?.linkTemplate,
                    action: \.destination.linkTemplate)) { store in
                        TemplatePickerView(store: store)
                    }
            .fullScreenCover(
                item: $store.scope(
                    state: \.destination?.summary,
                    action: \.destination.summary)) { store in
                        NavigationStack {
                            SummaryView(store: store)
                        }
                    }
    }

    // MARK: - Link Template Toolbar Item

    /// Toolbar button — tylko "Podpnij plan" gdy workout nie ma podpiętego planu
    /// (`loadState == .notFound`), jako escape hatch dla nieudanego
    /// `.saving → .summary` flow.
    /// Gdy plan jest podpięty (`.loaded`) edycja odbywa się w treści ekranu:
    /// puste wyniki → klikalny kontener "Wyniki" (`ActivityPlanScoreView.pendingResultsHint`),
    /// wypełnione → przyciski "Edytuj" pod każdym WOD-em. Brak przycisku w toolbarze.
    /// Loading/failed → button schowany.
    @ToolbarContentBuilder
    private var linkTemplateToolbarItem: some ToolbarContent {
        switch store.planScore.loadState {
        case .notFound:
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    send(.linkTemplateTapped)
                } label: {
                    Text(linkTemplateButtonTitle)
                }
            }
        case .loaded, .loading, .failed:
            ToolbarItem(placement: .topBarTrailing) { EmptyView() }
        }
    }

    private var linkTemplateButtonTitle: String {
        String(localized: "Podpnij plan")
    }

    private var navigationTitleText: String {
        store.workout.startDate.formatted(date: .abbreviated, time: .omitted)
    }

    private var rootView: some View {
        ScrollView {
            VStack(spacing: 8) {
                ActivityHeaderView(workout: store.workout)
                EnergySectionView(workout: store.workout, formattedMETs: store.performanceMetrics.formattedMETs)
                HeartRateSectionView(workout: store.workout)
                HeartRateZonesView(store: store.scope(state: \.heartRateZones, action: \.heartRateZones))
                PerformanceMetricsView(store: store.scope(state: \.performanceMetrics, action: \.performanceMetrics))
                WorkoutRouteView(store: store.scope(state: \.workoutRoute, action: \.workoutRoute))
                ClassRecapView(store: store.scope(state: \.classRecap, action: \.classRecap))
                planScoreSection
            }
        }
    }

    // MARK: - Plan Score

    private var planScoreSection: some View {
        ActivityPlanScoreView(store: store.scope(state: \.planScore, action: \.planScore))
    }
}

// MARK: - Preview

#Preview("without plan") {
    let workout = HKWorkout(
        activityType: .crossTraining,
        start: Date().addingTimeInterval(-3600),
        end: Date()
    )
    return NavigationStack {
        ActivityDetailsView(store: Store(
            initialState: ActivityDetailsFeature.State(workout: workout, maxHeartRate: 185)
        ) {
            ActivityDetailsFeature()
        } withDependencies: {
            $0.workoutPlanScoreClient.fetchByHKWorkoutId = { _ in nil }
        })
    }
}

#Preview("with effort points") {
    let workout = HKWorkout(
        activityType: .crossTraining,
        start: Date().addingTimeInterval(-3600),
        end: Date()
    )
    return NavigationStack {
        ActivityDetailsView(store: Store(
            initialState: ActivityDetailsFeature.State(workout: workout, maxHeartRate: 185)
        ) {
            ActivityDetailsFeature()
        } withDependencies: {
            $0.workoutPlanScoreClient.fetchByHKWorkoutId = { _ in nil }
            // Zone distribution present → the HR-zones section renders, so its
            // header (with the points badge) is visible in the canvas. Same
            // secondsByZone as the stored score, so time↔points rows agree:
            // 5·1 + 20·4 + 10·6 = 5 + 80 + 60 = 145 pkt.
            $0.activityClient.fetchZoneDistribution = { _, _ in
                [.recovery: 300, .aerobic: 1200, .threshold: 600]
            }
            $0.effortScoreClient.fetchByHKWorkoutId = { id in
                WorkoutEffortScore(
                    id: UUID(),
                    hkWorkoutId: id,
                    points: 145,
                    workoutStartDate: Date(),
                    secondsByZone: [.recovery: 300, .aerobic: 1200, .threshold: 600],
                    weightsVersion: 1
                )
            }
        })
    }
}

#Preview("with plan") {
    let session = TrainingSession.previewTrainingSession
    let workout = HKWorkout(
        activityType: .crossTraining,
        start: Date().addingTimeInterval(-3600),
        end: Date()
    )
    let score = WorkoutPlanScore(
        trainingSessionId: session.id,
        hkWorkoutId: workout.uuid,
        results: session.workouts.map {
            WorkoutSessionResult(
                name: $0.name,
                description: $0.snapshotDescription,
                scoreResult: $0.name == "WOD 1" ? .custom("11:43") : .forLoad(weight: 80),
                note: ""
            )
        }
    )
    return NavigationStack {
        ActivityDetailsView(store: Store(
            initialState: ActivityDetailsFeature.State(workout: workout, maxHeartRate: 185)
        ) {
            ActivityDetailsFeature()
        } withDependencies: {
            $0.workoutPlanScoreClient.fetchByHKWorkoutId = { _ in score }
        })
    }
}
