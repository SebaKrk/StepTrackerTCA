//
//  ScannedSet.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 29/10/2026.
//

import Foundation

/// One entry of a set scheme ("5x5 @ 80 kg" → five of these). `value` 0 with `maxEffort` = "max".
public struct ScannedSet: Codable, Sendable, Equatable {
    /// Count of the set; 0 together with `maxEffort`.
    public let value: Double

    /// True for a "max" set.
    public let maxEffort: Bool

    /// What `value` counts.
    public let unit: SetUnit

    /// Load of the set; 0 when the set has no load.
    public let load: Double

    /// Unit of `load`; `none` when `load` is 0.
    public let loadUnit: ScannedLoadUnit

    public init(value: Double, maxEffort: Bool = false, unit: SetUnit = .reps, load: Double = 0, loadUnit: ScannedLoadUnit = .none) {
        self.value = value
        self.maxEffort = maxEffort
        self.unit = unit
        self.load = load
        self.loadUnit = loadUnit
    }
}
