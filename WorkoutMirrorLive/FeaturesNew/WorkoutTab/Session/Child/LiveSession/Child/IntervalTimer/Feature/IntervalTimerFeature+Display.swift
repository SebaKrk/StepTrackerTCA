//
//  IntervalTimerFeature+Display.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 08/09/2026.
//

import SharedModels
import SwiftUI

/// Display helpers shared by the portrait tile (`IntervalTimerView`) and the
/// landscape card (`IntervalTimerLandscapeView`) — one source of truth so the
/// two orientations can never drift apart on colors, labels, or countdown math.
extension IntervalTimerFeature.State {

    /// True while a session pause has frozen the running segment.
    var isPaused: Bool { pausedRemaining != nil }

    /// Traffic-light semantics on the HeartRateZone system palette:
    /// green = fight, red = stop and recover.
    var accent: Color {
        if isPaused { return Self.pausedAccent }
        switch phase {
        case .work:      return Self.workAccent
        case .rest:      return Self.restAccent
        case .countdown: return Self.readyAccent
        case .idle, .finished: return Self.workAccent
        }
    }

    static let workAccent = Color.green      // HeartRateZone.fatBurning
    static let restAccent = Color.red        // HeartRateZone.anaerobic
    static let readyAccent = Color.yellow    // HeartRateZone.aerobic
    static let pausedAccent = Color.gray     // HeartRateZone.resting

    /// State-pill label. Deliberately "Box", not "Work" — the tile talks gym
    /// language; the plan editor keeps the generic Work/Rest wording.
    var segmentTitle: String {
        if isPaused { return String(localized: "Paused") }
        switch phase {
        case .countdown: return String(localized: "Get ready")
        case .work:      return String(localized: "Box")
        case .rest:      return String(localized: "Rest")
        case .idle, .finished: return ""
        }
    }

    /// "30 s / 30 s × 12" one-line summary of the config.
    var configSummary: String {
        "\(secondsLabel(config.workSeconds)) / \(secondsLabel(config.restSeconds)) × \(config.rounds)"
    }

    /// "6:00 · 5:30" work/rest totals for the finished card.
    var finishedSummary: String {
        let workTotal = config.rounds * config.workSeconds
        let restTotal = max(0, config.rounds - 1) * config.restSeconds
        return "\(minutesLabel(workTotal)) · \(minutesLabel(restTotal))"
    }

    /// Frozen remaining seconds during a pause, live countdown otherwise.
    func remainingSeconds(at renderDate: Date) -> Int {
        if let frozen = pausedRemaining {
            return Int(frozen.rounded(.up))
        }
        guard let end = segmentEndDate else { return 0 }
        return max(0, Int(end.timeIntervalSince(renderDate).rounded(.up)))
    }

    /// mm:ss above a minute, bare seconds below — the big countdown digits.
    func remainingLabel(at renderDate: Date) -> String {
        let seconds = remainingSeconds(at: renderDate)
        return seconds >= 60
            ? String(format: "%d:%02d", seconds / 60, seconds % 60)
            : "\(seconds)"
    }

    /// Fraction of the running segment still ahead (1 → 0), for progress bars.
    func segmentFraction(at renderDate: Date) -> CGFloat {
        let total: Int
        switch phase {
        case .work:      total = config.workSeconds
        case .rest:      total = config.restSeconds
        case .countdown: total = IntervalTimerFeature.countdownSeconds
        case .idle, .finished: return 0
        }
        guard total > 0 else { return 0 }
        return CGFloat(remainingSeconds(at: renderDate)) / CGFloat(total)
    }
}

/// "45 s" below a minute, "3:00" above.
private func secondsLabel(_ seconds: Int) -> String {
    seconds < 60
        ? "\(seconds) s"
        : String(format: "%d:%02d", seconds / 60, seconds % 60)
}

private func minutesLabel(_ seconds: Int) -> String {
    String(format: "%d:%02d", seconds / 60, seconds % 60)
}
