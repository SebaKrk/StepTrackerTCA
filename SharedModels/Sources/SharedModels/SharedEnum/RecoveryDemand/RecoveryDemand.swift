//
//  RecoveryDemand.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 04/01/2026.
//

import Foundation

/// Represents estimated recovery time after a workout.
public struct RecoveryDemand: Equatable, Sendable {
    
    /// Estimated recovery time in hours.
    public let hours: Double
    
    /// Recovery demand level classification.
    public var level: RecoveryDemandLevel {
        RecoveryDemandLevel.from(hours: hours)
    }
    
    public init(hours: Double) {
        self.hours = hours
    }
}
