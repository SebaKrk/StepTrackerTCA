//
//  BackgroundDeliveryManager.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 28/01/2026.
//

import HealthKit

/// Low-level protocol for managing HealthKit background delivery.
/// Provides streams of notifications when new health data is available.
public protocol BackgroundDeliveryManager: Sendable {
    
    /// Enables background delivery for specified health data types.
    ///
    /// - Parameters:
    ///   - types: Set of HealthKit sample types to observe
    ///   - frequency: How often to receive updates (.immediate, .hourly, .daily, .weekly)
    /// - Throws: HealthKit errors if background delivery cannot be enabled
    func enable(
        for types: Set<HKSampleType>,
        frequency: HKUpdateFrequency
    ) async throws
    
    /// Disables background delivery for specified health data types.
    ///
    /// - Parameter types: Set of HealthKit sample types to stop observing
    /// - Throws: HealthKit errors if background delivery cannot be disabled
    func disable(for types: Set<HKSampleType>) async throws
    
    /// Creates an observation stream for a specific health data type.
    ///
    /// The stream emits `Void` whenever HealthKit notifies that new data is available
    /// for the specified type. The stream remains active until the Task is cancelled.
    ///
    /// - Parameter type: The HealthKit sample type to observe
    /// - Returns: AsyncStream that emits when new data arrives
    func observationStream(for type: HKSampleType) async -> AsyncStream<Void>
    
    /// Checks if background delivery is currently enabled for a type.
    ///
    /// Note: This only checks if we've called enable() - it doesn't query HealthKit's state
    ///
    /// - Parameter type: The HealthKit sample type to check
    /// - Returns: `true` if background delivery is enabled for this type
    func isEnabled(for type: HKSampleType) async -> Bool
}
