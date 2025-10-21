//
//  DailyActivityChartData.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 21/10/2025.
//

import Foundation

/// Represents aggregated activity data for the entire day
public struct DailyActivityChartData: Sendable, Equatable {
    
    public let hourlyData: [HourlyActivityData]
    public let totalActiveEnergy: Double
    public let totalExerciseMinutes: Double
    public let totalStandHours: Int
    
    public init(hourlyData: [HourlyActivityData]) {
        self.hourlyData = hourlyData
        self.totalActiveEnergy = hourlyData.reduce(0) { $0 + $1.activeEnergyBurned }
        self.totalExerciseMinutes = hourlyData.reduce(0) { $0 + $1.exerciseMinutes }
        self.totalStandHours = hourlyData.reduce(0) { $0 + $1.standHours }
    }
}
