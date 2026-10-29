//
//  ScannedMovement.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 29/10/2026.
//

import Foundation

/// One movement line of a block. Sentinels instead of optionals: 0, "" and [] mean "not on the board".
public struct ScannedMovement: Codable, Sendable, Equatable {
    /// Normalised movement name the catalog can match ("kettlebell swing").
    public let name: String

    /// Exactly as written, for the unknown-exercise radar.
    public let rawName: String

    /// Where the movement sits in the WOD; `round` unless marked otherwise.
    public let segment: MovementSegment

    /// Single target of the movement; 0 when `sets` or the section's rep scheme carry the numbers.
    public let targetValue: Double

    /// Unit of `targetValue`.
    public let targetUnit: ScannedTargetUnit

    /// Upper bound of a rep range ("8-12" → target 8, max 12); 0 when none.
    public let repRangeMax: Int

    /// "8/8", "10 per side": the target is per limb.
    public let perSide: Bool

    /// "max reps" / "max cal": there is no target.
    public let maxEffort: Bool

    /// Set scheme, one entry per set; empty for WOD movements.
    public let sets: [ScannedSet]

    /// Load options printed after the movement; empty when the load sits in `sets`.
    public let loads: [ScannedLoad]

    /// Rest after each set in seconds; 0 when no rest is written.
    public let restAfterSetSec: Int

    /// Alternative movements: "row or run" → ["running"].
    public let alternatives: [String]

    public init(
        name: String,
        rawName: String = "",
        segment: MovementSegment = .round,
        targetValue: Double = 0,
        targetUnit: ScannedTargetUnit = .reps,
        repRangeMax: Int = 0,
        perSide: Bool = false,
        maxEffort: Bool = false,
        sets: [ScannedSet] = [],
        loads: [ScannedLoad] = [],
        restAfterSetSec: Int = 0,
        alternatives: [String] = []
    ) {
        self.name = name
        self.rawName = rawName
        self.segment = segment
        self.targetValue = targetValue
        self.targetUnit = targetUnit
        self.repRangeMax = repRangeMax
        self.perSide = perSide
        self.maxEffort = maxEffort
        self.sets = sets
        self.loads = loads
        self.restAfterSetSec = restAfterSetSec
        self.alternatives = alternatives
    }
}
