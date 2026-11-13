//
//  ReadinessAvailability.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 08/11/2026.
//

import Foundation

/// Whether a readiness score can exist yet today.
///
/// Kept beside `ContentState` rather than inside it: fifteen features share that
/// enum, and waiting on sleep data concerns only this one.
enum ReadinessAvailability: Equatable {

    /// The day can be scored.
    case available

    /// The night has not ended yet, so there is nothing complete to score.
    ///
    /// - Parameter expectedBy: When a result should become available, if known.
    case awaitingSleepData(expectedBy: Date?)
}
