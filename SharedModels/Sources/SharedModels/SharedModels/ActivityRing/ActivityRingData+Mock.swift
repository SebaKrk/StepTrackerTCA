//
//  ActivityRingData+mock.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 09/11/2025.
//

import Foundation

public extension ActivityRingData {
    
    /// Default mock with moderate progress
    static let mock = Self.good
    
    /// Empty day - no activity yet
    static let empty = Self(
        moveValue: 0,
        moveGoal: 850.0,
        exerciseValue: 0,
        exerciseGoal: 60.0,
        standValue: 0,
        standGoal: 12.0
    )
    
    /// Early morning - just started the day
    static let morning = Self(
        moveValue: 120.0,
        moveGoal: 850.0,
        exerciseValue: 5.0,
        exerciseGoal: 60.0,
        standValue: 2.0,
        standGoal: 12.0
    )
    
    /// Moderate progress - halfway through the day
    static let moderate = Self(
        moveValue: 450.0,
        moveGoal: 850.0,
        exerciseValue: 30.0,
        exerciseGoal: 60.0,
        standValue: 8.0,
        standGoal: 12.0
    )
    
    /// Good progress - almost there
    static let good = Self(
        moveValue: 650.0,
        moveGoal: 850.0,
        exerciseValue: 45.0,
        exerciseGoal: 60.0,
        standValue: 10.0,
        standGoal: 12.0
    )
    
    /// All rings completed
    static let completed = Self(
        moveValue: 920.0,
        moveGoal: 850.0,
        exerciseValue: 65.0,
        exerciseGoal: 60.0,
        standValue: 12.0,
        standGoal: 12.0
    )
    
    /// Exceeded all goals
    static let exceeded = Self(
        moveValue: 1200.0,
        moveGoal: 850.0,
        exerciseValue: 90.0,
        exerciseGoal: 60.0,
        standValue: 14.0,
        standGoal: 12.0
    )
    
    /// Low activity day
    static let low = Self(
        moveValue: 180.0,
        moveGoal: 850.0,
        exerciseValue: 10.0,
        exerciseGoal: 60.0,
        standValue: 4.0,
        standGoal: 12.0
    )
    
    /// Weekend warrior - high activity
    static let highActivity = Self(
        moveValue: 1500.0,
        moveGoal: 850.0,
        exerciseValue: 120.0,
        exerciseGoal: 60.0,
        standValue: 15.0,
        standGoal: 12.0
    )
}
