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
        
        var trainingSession: TrainingSession? = nil
        
        // MARK: - Title
        
        var isWorkoutTitleSheetPresented: Bool = false
        
        var workoutTitle: String = ""
        
        // MARK: - Workout type
        
        var workoutActivityType: WorkoutActivityType = .crossTraining
        
        var availableWorkoutTypes: [WorkoutActivityType] = [.crossTraining]
        
        // MARK: - Workout Location
        
        var workoutLocationType: WorkoutLocationType = .indoor
        
        // MARK: - WarmUp
        
        var warmupGoal: SimpleWorkoutGoal = .open
        
        var warmUpGoalTime: Int? = nil
        
        var isWarmUpSheetPresented: Bool = false
        
        var warmUpNote: String = ""
        
        // MARK: - WODS
        
        var wods: [WorkoutSessionNew] = []
        
        // MARK: - CoolDown
        
        var coolDownGoal: SimpleWorkoutGoal = .open
        
        var coolDownTime: Int? = nil
        
        var isCoolDownSheetPresented: Bool = false
        
        
        var availableTime: [Int] = Array(stride(from: 5, through: 60, by: 5))
        
        
        // MARK: - Destination
        
        @Presents var destination: Destination.State?
        
    }
    
}
