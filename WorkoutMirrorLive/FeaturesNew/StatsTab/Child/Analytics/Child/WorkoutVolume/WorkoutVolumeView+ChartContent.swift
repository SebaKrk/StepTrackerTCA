//
//  WorkoutVolumeView+ChartContent.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 18/04/2026.
//

import SwiftUI

extension WorkoutVolumeView {

    // MARK: - Activity Segment Helpers

    func uniqueActivityNames(from data: [WorkoutVolumeFeature.WeeklyActivitySegment]) -> [String] {
        var seen: Set<String> = []
        var names: [String] = []
        for segment in data {
            if seen.insert(segment.activityName).inserted {
                names.append(segment.activityName)
            }
        }
        return names
    }

    func uniqueActivityColors(from data: [WorkoutVolumeFeature.WeeklyActivitySegment]) -> [Color] {
        var seen: Set<String> = []
        var colors: [Color] = []
        for segment in data {
            if seen.insert(segment.activityName).inserted {
                colors.append(segment.activityColor)
            }
        }
        return colors
    }

    // MARK: - Duration Formatting

    func formatMinutes(_ totalMinutes: Double) -> String {
        let hours = Int(totalMinutes) / 60
        let minutes = Int(totalMinutes) % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    func formatMinutesAxis(_ minutes: Double) -> String {
        if minutes >= 60 {
            let h = Int(minutes) / 60
            return "\(h)h"
        }
        return "\(Int(minutes))m"
    }
}
