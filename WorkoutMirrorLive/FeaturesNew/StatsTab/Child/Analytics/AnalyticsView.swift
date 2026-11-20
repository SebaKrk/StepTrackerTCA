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
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 12) {
                    // A marker of its own, never a section: every section here
                    // is conditional, and `scrollTo` on an id that is not in
                    // the hierarchy does nothing at all, silently.
                    Color.clear
                        .frame(height: 0)
                        .id(Self.topAnchor)
                    workoutVolumeSection()
                    weightTrendSection()
                    readinessTrendSection()
                    healthMetricsTrendSection()
                }
            }
            // The offset at rest is the negated top inset, so the sum is zero
            // exactly when the view sits at its top.
            .onScrollGeometryChange(for: Bool.self) { geometry in
                geometry.contentOffset.y + geometry.contentInsets.top > 1
            } action: { _, isScrolled in
                send(.scrolledChanged(isScrolled))
            }
            .onChange(of: store.scrollToTopToken) {
                withAnimation { proxy.scrollTo(Self.topAnchor, anchor: .top) }
            }
            .onAppear {
                send(.viewDidAppear)
            }
        }
    }

    /// Identifies the first section, so the proxy has something to scroll back to.
    private static let topAnchor = "analytics-top"

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
