//
//  HeartRateSectionView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 16/07/2026.
//

import HealthKit
import SwiftUI

/// Average / max heart-rate cards. Pure presentation of `HKWorkout`
/// statistics — no reducer.
struct HeartRateSectionView: View {

    let workout: HKWorkout

    var body: some View {
        LazyVGrid(columns: MetricCardGrid.twoColumns, spacing: 4) {
            SimpleMetricCard(
                title: String(localized: "Avg HR", bundle: .main),
                value: formattedAvgHR,
                unit: "bpm",
                icon: "heart.fill"
            )
            SimpleMetricCard(
                title: String(localized: "Max HR", bundle: .main),
                value: formattedMaxHR,
                unit: "bpm",
                icon: "heart.fill"
            )
        }
    }

    // MARK: - Implementation

    private var formattedAvgHR: String {
        guard let avgHR = workout.statistics(for: HKQuantityType(.heartRate))?
            .averageQuantity()?
            .doubleValue(for: .count().unitDivided(by: .minute())) else {
            return "—"
        }
        return "\(Int(avgHR))"
    }

    private var formattedMaxHR: String {
        guard let maxHR = workout.statistics(for: HKQuantityType(.heartRate))?
            .maximumQuantity()?
            .doubleValue(for: .count().unitDivided(by: .minute())) else {
            return "—"
        }
        return "\(Int(maxHR))"
    }
}
