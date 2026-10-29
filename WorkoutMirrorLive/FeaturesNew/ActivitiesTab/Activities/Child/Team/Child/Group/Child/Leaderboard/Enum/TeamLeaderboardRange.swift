//
//  TeamLeaderboardRange.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import Foundation

/// Leaderboard period on the group screen.
enum TeamLeaderboardRange: CaseIterable, Identifiable, Equatable {

    /// The shown day's plan only.
    case day

    /// Effort points and kcal summed Monday to Sunday.
    case week

    var id: Self { self }

    var title: String {
        switch self {
        case .day: String(localized: "Day")
        case .week: String(localized: "Week")
        }
    }
}
