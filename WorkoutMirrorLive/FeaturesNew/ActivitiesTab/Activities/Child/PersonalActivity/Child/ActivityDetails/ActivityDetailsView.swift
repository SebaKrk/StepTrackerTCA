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
            .background(backgroundGradient.ignoresSafeArea())
            .toolbar { linkTemplateToolbarItem }
            .onAppear { send(.viewDidAppear) }
            .navigationDestination(
                item: $store.scope(
                    state: \.destination?.metricDetail,
                    action: \.destination.metricDetail)) { store in
                        MetricDetailView(store: store)
                    }
            .navigationDestination(
                item: $store.scope(
                    state: \.destination?.roundsDetail,
                    action: \.destination.roundsDetail)) { store in
                        RoundsDetailView(store: store)
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

    private var rootView: some View {
        ScrollView {
            VStack(spacing: 8) {
                headerSection
                energySection
                heartRateSection
                heartRateZonesSection
                performanceMetricsSection
                routeSection
                classRecapSection
                planScoreSection
                roundsSection
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        ActivityHeaderView(workout: store.workout)
    }

    private var energySection: some View {
        EnergySectionView(workout: store.workout, formattedMETs: store.performanceMetrics.formattedMETs)
    }

    private var heartRateSection: some View {
        HeartRateSectionView(workout: store.workout)
    }

    private var heartRateZonesSection: some View {
        HeartRateZonesView(store: store.scope(state: \.heartRateZones, action: \.heartRateZones))
    }

    private var performanceMetricsSection: some View {
        PerformanceMetricsView(store: store.scope(state: \.performanceMetrics, action: \.performanceMetrics))
    }

    private var routeSection: some View {
        WorkoutRouteView(store: store.scope(state: \.workoutRoute, action: \.workoutRoute))
    }

    private var classRecapSection: some View {
        ClassRecapView(store: store.scope(state: \.classRecap, action: \.classRecap))
    }

    private var planScoreSection: some View {
        ActivityPlanScoreView(store: store.scope(state: \.planScore, action: \.planScore))
    }

    // MARK: - Rounds

    /// Entry card of the rounds analysis — bottom of the screen, only for
    /// workouts that carry rounds-timer segments in their events.
    @ViewBuilder
    private var roundsSection: some View {
        if !store.roundSegments.isEmpty {
            roundsCardButton
        }
    }

    private var roundsCardButton: some View {
        Button {
            send(.roundsCardTapped)
        } label: {
            roundsCardLabel
        }
        .buttonStyle(.plain)
    }

    private var roundsCardLabel: some View {
        GroupBox {
            HStack(spacing: 12) {
                Image(systemName: "figure.boxing")
                    .font(.title3)
                    .foregroundStyle(.primary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(roundsCardTitle)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(verbatim: roundsCardSubtitle)
                        .font(.footnote)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .styledGroupBox()
    }

    private var roundsCardTitle: String {
        store.workout.workoutActivityType == .boxing
            ? String(localized: "Rounds — Boxing")
            : String(localized: "Rounds")
    }

    /// "12 × 0:30 / 0:30" — completed rounds and the typical (median) durations.
    private var roundsCardSubtitle: String {
        let segments = store.roundSegments
        let workDurations = segments.filter { $0.kind == .work }.map(\.dateInterval.duration)
        let restDurations = segments.filter { $0.kind == .rest }.map(\.dateInterval.duration)
        let work = durationLabel(median(of: workDurations))
        let restMedian = median(of: restDurations)
        // rest = 0 s (no rest segments) — the subtitle drops its "/ rest" part.
        guard restMedian > 0 else {
            return "\(workDurations.count) × \(work)"
        }
        return "\(workDurations.count) × \(work) / \(durationLabel(restMedian))"
    }

    private func median(of values: [TimeInterval]) -> TimeInterval {
        let sorted = values.sorted()
        guard !sorted.isEmpty else { return 0 }
        return sorted[sorted.count / 2]
    }

    private func durationLabel(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        return total < 60 ? "\(total) s" : String(format: "%d:%02d", total / 60, total % 60)
    }

    // MARK: - Toolbar

    /// Toolbar button — tylko "Dodaj plan" gdy workout nie ma podpiętego planu
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
                linkTemplateButton
            }
        case .loaded, .loading, .failed:
            ToolbarItem(placement: .topBarTrailing) { EmptyView() }
        }
    }

    private var linkTemplateButton: some View {
        Button {
            send(.linkTemplateTapped)
        } label: {
            Label(linkTemplateButtonTitle, systemImage: linkTemplateButtonIcon)
        }
    }

    private var linkTemplateButtonTitle: String {
        String(localized: "Add plan")
    }

    private var linkTemplateButtonIcon: String {
        "link.badge.plus"
    }

    // MARK: - Implementation

    private var navigationTitleText: String {
        store.workout.startDate.formatted(date: .abbreviated, time: .omitted)
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [store.color.opacity(0.25), .clear],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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
