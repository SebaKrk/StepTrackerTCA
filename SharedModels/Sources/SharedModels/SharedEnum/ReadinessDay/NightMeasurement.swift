//
//  NightMeasurement.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 09/11/2026.
//

import Foundation

/// What a night's sleep recording actually says.
///
/// Sleep samples alone cannot tell these apart: a Watch on the charger and a user
/// who never fell asleep both produce no samples at all, and a Watch that ran out
/// of battery produces a short night indistinguishable from a genuinely short one.
/// Scoring cannot decide between them, so it is told instead.
public enum NightMeasurement: Sendable, Equatable {

    /// Sleep was recorded and the recording looks complete.
    case measured(hours: Double)

    /// The Watch was worn through the night and recorded no sleep at all.
    case noSleep

    /// Nothing was recorded, so nothing can be said about the night.
    case notWorn

    /// The recording stopped part-way through the night.
    case truncated
}
