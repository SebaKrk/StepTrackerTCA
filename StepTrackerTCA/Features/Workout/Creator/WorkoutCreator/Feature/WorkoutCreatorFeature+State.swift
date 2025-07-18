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
        
        /// Complete training session created from all configured components
        var trainingSession: TrainingSession? = nil
        
        // MARK: - Title
        
        /// Controls presentation of the workout title editing sheet
        var isWorkoutTitleSheetPresented: Bool = false
        
        /// User-defined title for the workout
        var workoutTitle: String = ""
        
        // MARK: - Workout type
        
        /// Selected workout activity type (e.g., crossTraining, running, cycling)
        var workoutActivityType: WorkoutActivityType? = nil
        //= .crossTraining
        
        /// Available workout activity types for selection
        var availableWorkoutTypes: [WorkoutActivityType] = [.crossTraining]
        
        // MARK: - Workout Location
        
        /// Selected workout location (indoor, outdoor, unknown)
        var workoutLocationType: WorkoutLocationType = .indoor
        
        // MARK: - WODS
        
        /// Collection of Workouts of the Day (WODs) that make up the main training
        var wods: [WorkoutSessionNew] = []
        
        // MARK: - Session Data
        
        /// Configured warm up session with goal, time, and notes
        var warmUpSession: WarmUpSession? = nil
        
        /// Configured cool down session with goal, time, and notes
        var coolDownSession: CoolDownSession? = nil
        
        // MARK: - Destination
        
        /// Navigation destination for presenting WOD creator or workout preview
        @Presents var destination: Destination.State?
        
        // MARK: - Computed Properties
        
        /// Display text for warm up button showing current configuration
        /// Returns "Open" if no session configured, otherwise shows goal or time
        var warmUpDisplayText: String {
            guard let warmUp = warmUpSession else { return "Open" }
            return warmUp.goal == .open ? warmUp.goal.title : "\(warmUp.time ?? 0) minutes"
        }
        
        /// Display text for cool down button showing current configuration
        /// Returns "Open" if no session configured, otherwise shows goal or time
        var coolDownDisplayText: String {
            guard let coolDown = coolDownSession else { return "Open" }
            return coolDown.goal == .open ? coolDown.goal.title : "\(coolDown.time ?? 0) minutes"
        }
    }
}
