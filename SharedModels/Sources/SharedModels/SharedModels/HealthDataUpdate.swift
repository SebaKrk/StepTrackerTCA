//
//  HealthDataUpdate.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 29/01/2026.
//

import Foundation
import HealthKit

/// Represents a single health data update event delivered from HealthKit.
///
/// `HealthDataUpdate` is a lightweight domain model used to broadcast changes
/// originating from background delivery or live HealthKit updates to the
/// active application layer.
///
/// It encapsulates the updated sample type and the moment in time when the
/// update was observed, making it suitable for event streams, reducers,
/// and notification-based or unidirectional data flow architectures (e.g. TCA).
///
/// - Note: Conforms to `Sendable` for safe usage across Swift Concurrency
///   domains and `Hashable` to support diffing, sets, and dictionary keys.
public struct HealthDataUpdate: Sendable, Hashable {
    
    /// The HealthKit sample type that triggered this update.
    ///
    /// This typically represents a concrete `HKSampleType` such as
    /// `HKQuantityType` or `HKCategoryType` and can be used by consumers
    /// to route the update to the appropriate feature or handler.
    public let type: HKSampleType
    
    /// The timestamp indicating when this update was created or observed.
    ///
    /// Defaults to the current date at initialization time and can be used
    /// for ordering, debouncing, or filtering update events.
    public let timestamp: Date
    
    /// Creates a new health data update event.
    ///
    /// - Parameters:
    ///   - type: The HealthKit sample type that triggered the update.
    ///   - timestamp: The time when the update was observed. Defaults to `Date()`.
    public init(type: HKSampleType, timestamp: Date = Date()) {
        self.type = type
        self.timestamp = timestamp
    }
}
