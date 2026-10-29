//
//  ScannedLoadUnit.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 29/10/2026.
//

import Foundation

/// Unit of a load inside a set scheme; `none` when the set has no load.
public enum ScannedLoadUnit: String, Codable, Sendable, CaseIterable {
    /// Kilograms.
    case kg

    /// Pounds.
    case lb

    /// Percent of the athlete's one-rep max.
    case percentOfMax

    /// The set has no load.
    case none
}
