//
//  ReadinessDetailsFeature.swift
//  WorkoutMirror Watch App
//
//  Created by Sebastian Sciuba on 27/09/2026.
//

import ComposableArchitecture

/// Drives the breakdown of a readiness snapshot into its components,
/// where each metric can reveal an explanation of what it measures.
@Reducer
struct ReadinessDetailsFeature {

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case let .view(.metricTapped(metric)):
                // Tapping the expanded metric collapses it — only one is open at a time.
                state.expandedMetric = state.expandedMetric == metric ? nil : metric
                return .none
            }
        }
    }
}
