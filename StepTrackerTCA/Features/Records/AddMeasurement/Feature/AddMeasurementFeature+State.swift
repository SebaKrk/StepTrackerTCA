//
//  AddMeasurementFeature+State.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 19/02/2025.
//


import ComposableArchitecture
import Foundation

/// Implementation of `AddMeasurementFeature` state
extension AddMeasurementFeature {
    
    @ObservableState
    struct State: Equatable {
        
        // MARK: - Properties
        
        /// The date for which the user wants to add  data.
        /// Defaults to the current date.
        var addDataDate: Date = .now
        
        ///
        var selectedTime: Date = .now
        
        ///
        var workoutType: WorkoutType? = nil
        
        ///
        var weightliftingMovement: WeightliftingMovement? = nil
        
        ///
        var strengthMovement: StrengthMovement? = nil
        
        ///
        var fitnessMovement: FitnessMovement? = nil
        
        ///
        var crossMovement: CrossMovement? = nil
        
        ///
        var heroMovement: HeroMovement? = nil
        
        /// The value to add, entered as a string.
        var valueToAdd: String = ""
        
        /// The selected unit of measurement for weight.
        var weightUnit: WeightUnit = .kg
        
        ///
        var workoutUnit: WorkoutUnit = .reps
        
        // MARK: - Alert
        
        /// Optional alert message to be displayed.
        var alertMessage: String? = nil
        
        /// State of the alert presentation.
        @Presents var alert: AlertState<Action.Alert>?
        
    }
    
}
