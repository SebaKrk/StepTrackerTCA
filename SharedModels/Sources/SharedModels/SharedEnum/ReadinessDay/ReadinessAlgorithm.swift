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
    /// - 3: sleep scored purely against the user's own baseline, like every other
    ///   component — it was the last one adding points for an absolute duration
    /// - 4: a night with no sleep but heart rate throughout scores as zero sleep
    ///   instead of as missing data, and a recording that stopped mid-night drops
    ///   the component instead of being scored as a short night
    /// - 5: activity load range made symmetric (-5...+5), so a full set of
    ///   components maps points to the score one-to-one in both directions
    public static let currentVersion = 5
}
