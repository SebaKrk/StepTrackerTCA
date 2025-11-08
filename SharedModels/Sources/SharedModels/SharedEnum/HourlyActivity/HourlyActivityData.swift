//
//  HourlyActivityData.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 21/10/2025.
//

import Foundation

/// Represents activity data for a specific hour of the day
public struct HourlyActivityData: Sendable, Equatable, Identifiable {
    public let id = UUID()
    public let hour: Int // 0-23
    public let activeEnergyBurned: Double // kcal
    public let exerciseMinutes: Double // minutes
    public let standHours: Int // 0 or 1
    public let date: Date
    
    public init(
        hour: Int,
        activeEnergyBurned: Double,
        exerciseMinutes: Double,
        standHours: Int,
        date: Date
    ) {
        self.hour = hour
        self.activeEnergyBurned = activeEnergyBurned
        self.exerciseMinutes = exerciseMinutes
        self.standHours = standHours
        self.date = date
    }
}
