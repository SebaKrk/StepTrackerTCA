//
//  ScannedSectionFormat.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 29/10/2026.
//

import Foundation

/// Timing format written next to a block; `none` for plain set work.
public enum ScannedSectionFormat: String, Codable, Sendable, CaseIterable {
    /// Plain set work, no clock.
    case none

    /// For time.
    case forTime

    /// As many rounds as possible.
    case amrap

    /// Every minute on the minute (or E2MOM, see `everySec`).
    case emom

    /// Tabata.
    case tabata

    /// Work / rest intervals.
    case intervals

    /// "3 rounds not for time".
    case roundsUntimed

    /// "Max reps in N min".
    case maxEffort
}
