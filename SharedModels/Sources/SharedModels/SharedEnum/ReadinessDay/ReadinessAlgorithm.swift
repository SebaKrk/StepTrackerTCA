//
//  ReadinessAlgorithm.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 08/11/2026.
//

import Foundation

/// Versioning for the readiness scoring rules.
///
/// Stored alongside every saved score, so a trend chart can tell a change in the
/// user's recovery from a change in how the score is computed. Same invariant as
/// `ExerciseType.catalogVersion` and the Effort Points weights version.
public enum ReadinessAlgorithm {

    /// Version of the rules currently in use.
    ///
    /// **Bump this in the same commit** as any change to component weights,
    /// score thresholds, baseline windows or the normalisation formula.
    ///
    /// - 1: wake-anchored windows, normalised score, neutral day at 50
    /// - 2: day-grained signals read from whole calendar days, baselines exclude
    ///   the measured day and draw 7 days with data from a 49-day pool, the night
    ///   is the longest closed session rather than the most recent one, and sleep
    ///   baselines clip to the window instead of dropping straddling intervals.
    ///   HRV and sleep compare a session against sessions, never against clock
    ///   windows that also cover time awake
    public static let currentVersion = 2
}
