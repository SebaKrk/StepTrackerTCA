//
//  QuantitySampleSource.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 13/11/2026.
//

@preconcurrency import HealthKit
import Foundation

/// Supplies the raw quantity readings a personal metric is computed from.
///
/// Every repeated HealthKit read behind those metrics goes through here, which
/// lets a caller that already knows the range it needs — a history rebuild —
/// answer them from one pass instead of one query per day, while the code that
/// turns readings into numbers stays where it is.
public protocol QuantitySampleSource: Sendable {

    /// Reads every sample of a type across the span the windows cover.
    ///
    /// - Parameters:
    ///   - type: Quantity type to read
    ///   - windows: Windows the caller will group the result by
    /// - Returns: Samples within the overall span, oldest first
    /// - Throws: HealthKit errors if data access fails
    func quantitySamples(
        of type: HKQuantityType,
        covering windows: [ClosedRange<Date>]
    ) async throws -> [HKQuantitySample]

    /// Sums active energy per calendar day across the span the windows cover.
    ///
    /// - Parameter windows: Windows the caller will group the result by
    /// - Returns: Day start to total kilocalories, for days that burned anything
    /// - Throws: HealthKit errors if data access fails
    func dailyActiveEnergyTotals(
        covering windows: [ClosedRange<Date>]
    ) async throws -> [Date: Double]
}
