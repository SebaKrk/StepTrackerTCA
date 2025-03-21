//
//  SetEditGoalFeature+State.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 15/02/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `SetEditGoalFeature` state
extension SetEditGoalFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        /// The date for which the user wants to add  data.
        /// Defaults to the current date.
        var addDataDate: Date = .now
        
        /// Passed WorkoutType
        var workoutType: WorkoutType
        
        /// The selected MovementType
        var selectedMovement: (any MovementType)? = nil
        
        /// The selected weightlifting movement.
        var weightliftingMovement: WeightliftingMovement? = nil
        
        /// The selected strength movement.
        var strengthMovement: StrengthMovement? = nil
        
        /// The selected fitness movement.
        var fitnessMovement: FitnessMovement? = nil
        
        /// The selected cross movement.
        var crossMovement: CrossMovement? = nil
        
        /// The selected hero movement.
        var heroMovement: HeroMovement? = nil

        /// The selected unit of measurement for weight.
        var weightUnit: WeightUnit = .kg
        
        /// The selected unit of measurement for workout.
        var workoutUnit: WorkoutUnit = .reps
        
        /// The value to add, entered as a string.
        var valueToAdd: String = ""
        
        /// The value for cross training to add, entered as a string.
        var crossValueToAdd: String = ""
        
        /// The time interval for the measurement.
        var timeInterval: TimeInterval = 0
        
        /// The selected unit of measurement, used for the unit of value to add.
        var selectedUnit: String = ""
        
        // MARK: - Alert
        
        /// An optional alert message to be displayed.
        var alertMessage: String? = nil
        
        /// The state of the alert presentation.
        @Presents var alert: AlertState<Action.Alert>?
    }
    
}
