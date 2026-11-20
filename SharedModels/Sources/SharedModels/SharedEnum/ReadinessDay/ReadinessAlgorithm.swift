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
///
/// ## Contract
///
/// These rules hold across every component. Breaking one is a deliberate change
/// to what the score means rather than a fix, and bumps the version (K10).
///
/// **What the score means**
/// - **K1** — 50 is a day in line with the user's own norm, and a deviation
///   upwards weighs exactly as much as the same deviation downwards.
/// - **K2** — every component compares today against the user's own norm, never
///   against an absolute value or a population figure.
///
/// **Windows**
/// - **K3** — a window never ends in the future.
/// - **K4** — a window matches the granularity of its signal: daily aggregates
///   (resting heart rate, active energy) are read as whole calendar days, while
///   session signals (HRV, sleep) are read as the night's sleep session.
///
/// **Baselines**
/// - **K5** — the measured day is excluded from its own baseline.
/// - **K6** — a baseline takes N days *with data* out of a pool of M. A gap
///   reaches further back rather than shrinking the baseline.
///
/// **Missing data**
/// - **K7** — a missing component never lowers the score; the normalisation
///   divides by the components that are present.
/// - **K8** — a truncated recording drops its component, but no sleep while the
///   Watch was worn is zero hours of sleep: a result, not missing data.
///
/// **Stability**
/// - **K9** — the same day yields the same score, whenever it is computed.
/// - **K10** — changing any rule above bumps `currentVersion` in the same commit.
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
