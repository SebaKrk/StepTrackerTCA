//
//  ReadinessDetailsFeature+State.swift
//  WorkoutMirror Watch App
//
//  Created by Sebastian Sciuba on 27/09/2026.
//

import ComposableArchitecture
import SharedModels

/// Implementation of `ReadinessDetailsFeature` state.
extension ReadinessDetailsFeature {

    @ObservableState
    struct State: Equatable {

        /// Snapshot whose components are being inspected.
        let snapshot: ReadinessSnapshot

        /// Metric whose explanation is currently expanded, or `nil` when all are collapsed.
        var expandedMetric: HealthMetricType?
    }
}
