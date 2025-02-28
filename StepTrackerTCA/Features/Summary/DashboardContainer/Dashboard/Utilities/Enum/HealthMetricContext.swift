//
//  HealthMetricContext.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 22/12/2024.
//

import Foundation

/// Represents different health metrics that the user can track in the application.
///
/// The `HealthMetricContext` provides cases for:
/// - `steps`: Represents tracking of the user's step count.
/// - `weight`: Represents tracking of the user's weight.
enum HealthMetricContext: CaseIterable, Identifiable, Equatable {
    
    /// Tracks the number of steps taken.
    case steps
    
    /// Tracks the user's weight.
    case weight
    
    /// A unique identifier for each health metric.
    var id: Self { self }

    /// Health metric title
    var title: String {
        switch self {
        case .steps:
            return "Steps"
        case .weight:
            return "Weight"
        }
    }
    
}
