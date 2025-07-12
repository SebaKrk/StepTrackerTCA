//
//  WorkoutCreatorFeature+State.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 12/07/2025.
//

import ComposableArchitecture

/// Implementation of `WorkoutCreatorFeature` state
extension WorkoutCreatorFeature {
    
    @ObservableState
    struct State {
        
        var isWorkoutTitleSheetPresented: Bool = false
        
        var workoutTitle: String = ""
        
        var workoutActivityType: WorkoutActivityType = .crossTraining
        
        var availableWorkoutTypes: [WorkoutActivityType] = [.crossTraining]
        
        var workoutLocationType: WorkoutLocationType = .indoor
        
        var warmupGoal: SimpleWorkoutGoal = .open
        
        var warmUpGoalTime: Int = 1
        
        var coolDownGoal: SimpleWorkoutGoal = .open
        
        var coolDownTime: Int = 1
        
        var availableTime: [Int] = Array(1...60)
        
        // MARK: - Destination
        
        @Presents var destination: Destination.State?
        
    }
    
}
