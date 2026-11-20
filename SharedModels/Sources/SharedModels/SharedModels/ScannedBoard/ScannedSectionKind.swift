//
//  ScannedSectionKind.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 29/10/2026.
//

import Foundation

/// Role of a block on the board. Warm-up and cool-down carry text, the rest carry movements.
public enum ScannedSectionKind: String, Codable, Sendable, CaseIterable {
    /// Warm-up text written on the board.
    case warmup

    /// Technique work with little load.
    case skill

    /// Loaded set work.
    case strength

    /// Accessory set work after the main lift.
    case accessory

    /// Any block with a format keyword.
    case conditioning

    /// Stretches, holds, rehab.
    case mobility

    /// Cool-down text written on the board.
    case cooldown
}
