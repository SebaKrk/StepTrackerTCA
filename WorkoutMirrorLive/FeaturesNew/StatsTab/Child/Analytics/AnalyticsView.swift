//
//  AnalyticsView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 16/04/2026.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: AnalyticsFeature.self)
struct AnalyticsView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<AnalyticsFeature>

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                workoutVolumeSection()
                weightTrendSection()
                readinessTrendSection()
                healthMetricsTrendSection()
            }
        }
        .onAppear {
            send(.viewDidAppear)
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private func workoutVolumeSection() -> some View {
        if let store = store.scope(state: \.workoutVolume,
                                   action: \.workoutVolume) {
            WorkoutVolumeView(store: store)
        }
    }

    @ViewBuilder
    private func weightTrendSection() -> some View {
        if let store = store.scope(state: \.weightTrend,
                                   action: \.weightTrend) {
            WeightTrendView(store: store)
        }
    }

    @ViewBuilder
    private func readinessTrendSection() -> some View {
        if let store = store.scope(state: \.readinessTrend,
                                   action: \.readinessTrend) {
            ReadinessTrendView(store: store)
        }
    }

    @ViewBuilder
    private func healthMetricsTrendSection() -> some View {
        if let store = store.scope(state: \.healthMetricsTrend,
                                   action: \.healthMetricsTrend) {
            HealthMetricsTrendView(store: store)
        }
    }
}
