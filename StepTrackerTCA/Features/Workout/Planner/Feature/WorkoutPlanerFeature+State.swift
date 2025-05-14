//
//  WorkoutPlanerFeature+State.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 14/05/2025.
//

import ComposableArchitecture
import Foundation
import WorkoutKit

/// Implementation of `WorkoutPlanerFeature` state
extension WorkoutPlanerFeature {
    
    @ObservableState
    struct State: Equatable {
        
        // MARK: - Properties
        
        var workoutPlan: WorkoutPlan? = nil
        
        /// The date for which the user wants to add data.
        /// Defaults to the current date.
        var dateAndTime: Date = .now
        
        ///
        var workoutActivityType: WorkoutActivityType = .crossTraining
        
        ///
        var workoutLocationType: WorkoutLocationType = .indoor
        
        ///
        var energyGoalValueToAdd: String = ""
        
        ///
        var showPreview: Bool = false
    }
}
