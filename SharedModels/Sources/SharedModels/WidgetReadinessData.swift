//
//  WidgetReadinessData.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 24/01/2026.
//

import Foundation

/// Simplified DTO for widget data storage.
/// Contains only the essential fields needed by the widget.
public struct WidgetReadinessData: Codable, Sendable {
    public let overallScore: Int
    public let readinessLevelRaw: String
    public let rhrValue: Double?
    public let hrvValue: Double?
    public let sleepValue: Double?
    public let activityValue: Double?
    public let calculatedAt: Date
    
    public init(
        overallScore: Int,
        readinessLevelRaw: String,
        rhrValue: Double? = nil,
        hrvValue: Double? = nil,
        sleepValue: Double? = nil,
        activityValue: Double? = nil,
        calculatedAt: Date = Date()
    ) {
        self.overallScore = overallScore
        self.readinessLevelRaw = readinessLevelRaw
        self.rhrValue = rhrValue
        self.hrvValue = hrvValue
        self.sleepValue = sleepValue
        self.activityValue = activityValue
        self.calculatedAt = calculatedAt
    }
}
