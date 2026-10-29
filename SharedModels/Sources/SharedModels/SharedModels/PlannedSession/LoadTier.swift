//
//  LoadTier.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 29/10/2026.
//

import Foundation

/// One load option written next to a movement: "24/16", "Rx+ 28/20", "@ 70%".
///
/// Keeps the exact numbers the board shows. `WeightConfiguration` on the
/// exercise stays the rounded kg pair the session UI already understands.
public struct LoadTier: Equatable, Codable, Sendable {

    public enum Tier: String, Codable, Sendable, CaseIterable {
        /// A single load with no tier label; `men == women`.
        case single
        case rx
        case rxPlus
        case pro
        case scaled
    }

    public enum Unit: String, Codable, Sendable, CaseIterable {
        case kg
        case lb
        case pood
        case percentOfMax
    }

    public let tier: Tier
    public let men: Double?
    public let women: Double?
    public let unit: Unit

    public init(tier: Tier, men: Double?, women: Double?, unit: Unit) {
        self.tier = tier
        self.men = men
        self.women = women
        self.unit = unit
    }
}
