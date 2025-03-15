//
//  WorkoutSessionProtocol.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 15/03/2025.
//


import Factory
import Foundation

protocol WorkoutSessionProtocol: Identifiable, Equatable {
    var id: String { get }
    var workoutType: WorkoutType { get }
    var movement: any MovementType { get }
    var value: String { get }
    var date: Date { get }
}

struct WorkoutSummary {
    let workouts: [any WorkoutSessionProtocol]
}

struct NewGroupedWorkouts: Identifiable {
    var id: WorkoutType { workoutType }
    
    let workoutType: WorkoutType
    let movements: [NewGroupedMovement]
}

struct NewGroupedMovement: Identifiable {
    var id: String { movement.title }
    
    let movement: any MovementType
    let sessions: [any WorkoutSessionProtocol]
}
