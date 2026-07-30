//
//  EnergySectionView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 16/07/2026.
//

import HealthKit
import SwiftUI

/// Active calories + METs cards. Calories come straight from the workout;
/// METs is loaded asynchronously by the parent's metrics domain and passed
/// in already formatted — this view stays a dumb presenter.
struct EnergySectionView: View {

    let workout: HKWorkout
    let formattedMETs: String

    var body: some View {
        LazyVGrid(columns: MetricCardGrid.twoColumns, spacing: 4) {
            SimpleMetricCard(
                title: String(localized: "Calories Active", bundle: .main),
                value: formattedCalories,
                unit: "kcal",
                icon: "flame.fill"
            )
            SimpleMetricCard(
                title: String(localized: "METs", bundle: .main),
                value: formattedMETs,
                unit: "",
                icon: "bolt.fill"
            )
        }
    }

    // MARK: - Implementation

    private var formattedCalories: String {
        guard let calories = workout.statistics(for: HKQuantityType(.activeEnergyBurned))?
            .sumQuantity()?
            .doubleValue(for: .kilocalorie()) else {
            return "—"
        }
        return "\(Int(calories))"
    }
}
