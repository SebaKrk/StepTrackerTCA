//
//  SleepSampleSource.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 13/11/2026.
//

import Foundation
import SharedModels

/// Supplies the raw sleep readings a sleep metric is computed from.
///
/// Separate from `QuantitySampleSource` so each manager depends only on the
/// readings it actually asks for, even though one prefetch serves both.
public protocol SleepSampleSource: Sendable {

    /// Reads asleep intervals inside a window, dropping awake and in-bed periods.
    ///
    /// - Parameter window: Range to read intervals from
    /// - Returns: Intervals overlapping the window, oldest first
    /// - Throws: HealthKit errors if data access fails
    func asleepIntervals(
        in window: ClosedRange<Date>
    ) async throws -> [SleepSessionBuilder.Interval]
}
