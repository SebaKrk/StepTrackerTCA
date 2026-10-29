//
//  ScannedLoad.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 29/10/2026.
//

import Foundation

/// A load option printed after a movement: "24/16", "Rx+ 28/20". 0 = not written.
public struct ScannedLoad: Codable, Sendable, Equatable {
    /// Label of the option; `single` for a bare load.
    public let tier: LoadTier.Tier

    /// Load for men; 0 when not written.
    public let men: Double

    /// Load for women; 0 when not written.
    public let women: Double

    /// Unit of the pair.
    public let unit: LoadTier.Unit

    public init(tier: LoadTier.Tier, men: Double, women: Double, unit: LoadTier.Unit) {
        self.tier = tier
        self.men = men
        self.women = women
        self.unit = unit
    }
}
