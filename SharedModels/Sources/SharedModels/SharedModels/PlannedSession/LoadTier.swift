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

    /// Label of the load option on the board.
    public enum Tier: String, Codable, Sendable, CaseIterable {

        /// A single load with no tier label; `men == women`.
        case single

        /// Rx.
        case rx

        /// Rx+.
        case rxPlus

        /// Pro.
        case pro

        /// Scaled.
        case scaled
    }

    /// Unit the pair is written in.
    public enum Unit: String, Codable, Sendable, CaseIterable {

        /// Kilograms.
        case kg

        /// Pounds.
        case lb

        /// Pood, the kettlebell unit (1 pood = 16 kg).
        case pood

        /// Percent of the athlete's one-rep max.
        case percentOfMax
    }

    /// Which option this is.
    public let tier: Tier

    /// Load for men; nil when the board gives none.
    public let men: Double?

    /// Load for women; nil when the board gives none.
    public let women: Double?

    /// Unit of `men` and `women`.
    public let unit: Unit

    public init(tier: Tier, men: Double?, women: Double?, unit: Unit) {
        self.tier = tier
        self.men = men
        self.women = women
        self.unit = unit
    }
}
