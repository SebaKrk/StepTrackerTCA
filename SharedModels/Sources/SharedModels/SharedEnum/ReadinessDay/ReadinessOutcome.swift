//
//  ReadinessOutcome.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 08/11/2026.
//

import Foundation

/// What a readiness calculation produced, including the reasons it produced nothing.
///
/// Replaces inferring the situation from how many components came back `nil`:
/// "the night is not over yet" and "HealthKit access was denied" are different
/// answers, and only one of them is the user's problem to fix.
public enum ReadinessOutcome: Sendable, Equatable {

    /// A score was calculated for the day.
    case ready(TrainingReadinessResult)

    /// The night is still open, so scoring it would mean scoring half a night.
    ///
    /// - Parameter expectedBy: When a result should become available, if known.
    case awaitingSleepData(expectedBy: Date?)

    /// Too few components were available to score the day.
    case insufficientData

    /// HealthKit returned nothing at all, which points at missing permissions.
    case accessDenied

    /// The calculated result, or `nil` when the day could not be scored.
    public var result: TrainingReadinessResult? {
        guard case let .ready(result) = self else { return nil }
        return result
    }
}
