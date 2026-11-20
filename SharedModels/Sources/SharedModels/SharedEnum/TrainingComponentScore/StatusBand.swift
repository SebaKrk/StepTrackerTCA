//
//  StatusBand.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 09/11/2026.
//

import Foundation

/// A stretch of a component's score range that reads as one status.
///
/// Lets a gauge be drawn from the same thresholds the status label uses, instead
/// of a second copy of the rule that drifts away from it.
public struct StatusBand: Sendable, Equatable {

    /// Status every score inside the band maps to.
    public let status: ScoreStatus

    /// Bounds on the component's own score axis.
    public let range: ClosedRange<Double>

    /// Creates a band.
    ///
    /// - Parameters:
    ///   - status: Status the band represents
    ///   - range: Bounds on the score axis
    public init(status: ScoreStatus, range: ClosedRange<Double>) {
        self.status = status
        self.range = range
    }
}
