//
//  ActivityRingData.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 08/06/2025.
//

import Foundation

/// A structure representing the data for activity rings, including current values and goals for move, exercise, and stand activities.
public struct ActivityRingData: Equatable , Sendable {
    
    // MARK: - Properties
    
    /// The current value of the move activity.
    public var moveValue: Double
    
    /// The goal value for the move activity.
    public var moveGoal: Double
    
    /// The current value of the exercise activity.
    public var exerciseValue: Double
    
    /// The goal value for the exercise activity.
    public var exerciseGoal: Double
    
    /// The current value of the stand activity.
    public var standValue: Double
    
    /// The goal value for the stand activity.
    public var standGoal: Double
    
    // MARK: - Lifecycle
    
    public init(
        moveValue: Double,
        moveGoal: Double,
        exerciseValue: Double,
        exerciseGoal: Double,
        standValue: Double,
        standGoal: Double
    ) {
        self.moveValue = moveValue
        self.moveGoal = moveGoal
        self.exerciseValue = exerciseValue
        self.exerciseGoal = exerciseGoal
        self.standValue = standValue
        self.standGoal = standGoal
    }
    
}
