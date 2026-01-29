//
//  HealthDataUpdate.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 29/01/2026.
//

import Foundation
import HealthKit

/// Structure describing a health data update event.
/// Used to broadcast changes from background delivery to the active application.
public struct HealthDataUpdate: Sendable, Hashable {
    public let type: HKSampleType
    public let timestamp: Date
    
    public init(type: HKSampleType, timestamp: Date = Date()) {
        self.type = type
        self.timestamp = timestamp
    }
}
