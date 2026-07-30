//
//  WorkoutVolumeFeature+Model.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 16/04/2026.
//

import SwiftUI

extension WorkoutVolumeFeature {

    /// One segment = one activity type in one week.
    /// Multiple segments per week enable stacked bar chart.
    struct WeeklyActivitySegment: Identifiable, Equatable {
        var id: String { "\(weekStart.timeIntervalSince1970)-\(activityName)" }
        let weekStart: Date
        let activityName: String
        let activityColor: Color
        let durationMinutes: Double
        let count: Int
    }
}
