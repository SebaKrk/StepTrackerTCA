//
//  ReadinessCalculationError.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 08/11/2026.
//

import Foundation

/// Why a readiness calculation could not produce a score.
public enum ReadinessCalculationError: Error, Sendable, Equatable {

    /// The night has not ended yet, so there is nothing complete to score.
    ///
    /// - Parameter expectedBy: When a result should become available, if known.
    case awaitingSleepData(expectedBy: Date?)
}
