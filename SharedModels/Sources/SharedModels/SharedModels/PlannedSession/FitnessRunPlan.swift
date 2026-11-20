//
//  FitnessRunPlan.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 20/11/2026.
//

import Foundation

/// A run done before every station of a block; the stations are the block's movements.
public struct FitnessRunPlan: Codable, Equatable, Sendable {

    /// Distance of the run before each station, in metres.
    public let runMeters: Int

    public init(runMeters: Int) {
        self.runMeters = runMeters
    }

    /// Metres run over the whole block: one run per station.
    public func totalRunMeters(stationCount: Int) -> Int {
        runMeters * stationCount
    }
}
