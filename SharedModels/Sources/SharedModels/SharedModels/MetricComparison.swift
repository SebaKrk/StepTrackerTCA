//
//  MetricComparison.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 31/12/2025.
//

import Foundation

/// Represents comparison between current and historical metric values.
public struct MetricComparison: Sendable, Equatable {
    
    /// Absolute difference (current - average)
    public let difference: Double
    
    /// Percentage change from average
    public let percentageChange: Double
    
    /// Trend direction
    public let trend: Trend
    
    public enum Trend: Sendable, Equatable {
        case up
        case down
        case neutral
    }
    
    public init(difference: Double, percentageChange: Double, trend: Trend) {
        self.difference = difference
        self.percentageChange = percentageChange
        self.trend = trend
    }
}
