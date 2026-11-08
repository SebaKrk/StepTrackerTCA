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
    public static let currentVersion = 1
}
