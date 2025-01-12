//
//  ActivityPeriod.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 12/01/2025.
//

import Foundation

/// Represents the available activity periods for the user to select.
///
/// The `ActivityPeriod` enum provides predefined options for filtering
/// the user's activity data based on time periods. Each case has a unique identifier
/// and a human-readable title.
enum ActivityPeriod: CaseIterable, Identifiable, Equatable {
    
    /// Represents a single day of activity data.
    case day
    
    /// Represents four weeks (28 days) of activity data.
    case fourWeeks
    
    /// A unique identifier for each activity period.
    var id: Self { self }

    /// Activity period title
    var title: String {
        switch self {
        case .day:
            return "Day"
        case .fourWeeks:
            return "Weeks"
        }
    }
    
}
