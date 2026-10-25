//
//  TeamLeaderboardRange.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import Foundation

/// Leaderboard period on the group screen.
enum TeamLeaderboardRange: CaseIterable, Identifiable, Equatable {

    /// Today's plan only.
    case day

    /// Sum of daily places, Monday to Sunday.
    case week

    var id: Self { self }

    var title: String {
        switch self {
        case .day: String(localized: "Today")
        case .week: String(localized: "Week")
        }
    }
}
