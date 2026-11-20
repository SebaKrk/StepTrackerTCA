//
//  ProFeature.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 19/11/2026.
//

import Foundation

/// Everything the app sells with Pro, named once so no screen keeps its own rule.
public enum ProFeature: Equatable, CaseIterable, Sendable {

    /// Today's training readiness score and its explanation.
    case readiness

    /// The resting heart rate, HRV, sleep and activity cards.
    case healthCards

    /// The readiness chart over time.
    case readinessTrend

    /// The charts of single health metrics over time.
    case healthTrends

    /// The on-device analysis of the readiness data.
    case dataAnalyzer

    /// Workouts older than the most recent few.
    case olderWorkouts

    /// Plans older than the most recent few.
    case olderPlans

    /// The progress chart and the older history of a personal record.
    case recordProgress
}
