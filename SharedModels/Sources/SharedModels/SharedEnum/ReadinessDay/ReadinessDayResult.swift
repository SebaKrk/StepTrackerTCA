//
//  ReadinessDayResult.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 09/11/2026.
//

import Foundation

/// One scored day, paired with the day it describes.
///
/// History is written in batches during a backfill, and a result on its own does
/// not say which day it belongs to — the day carries the storage key.
public struct ReadinessDayResult: Sendable, Equatable {

    /// The score and its components.
    public let result: TrainingReadinessResult

    /// The day the score belongs to.
    public let day: ReadinessDay

    /// Creates a pair.
    ///
    /// - Parameters:
    ///   - result: The score and its components
    ///   - day: The day the score belongs to
    public init(result: TrainingReadinessResult, day: ReadinessDay) {
        self.result = result
        self.day = day
    }
}
