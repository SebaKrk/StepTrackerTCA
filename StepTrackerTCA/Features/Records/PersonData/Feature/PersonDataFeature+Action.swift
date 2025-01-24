//
//  PersonDataFeature+Action.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 23/01/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `PersonDataFeature` action
extension PersonDataFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Actions
        
        /// Triggers the fetching of health data.
        /// This action starts the process of retrieving health-related metrics from an external source.
        case fetchHealthData
        
        /// Updates the weight data with the result of a health data fetch.
        ///
        /// - Parameter result: A `Result` containing an array of `HealthData` on success
        /// or an `Error` on failure.
        case updateWeightData(Result<[HealthData], Error>)
                
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            /// The action responsible for completing tasks as soon as the view is displayed.
            case viewDidAppear
        }
        
        // MARK: - Destination
        
        /// destination case for navigation
        case destination(PresentationAction<Destination.Action>)
        
        // MARK: - Child actions
        
        /// Stores the actions of the `CurrentWeightFeature`
        case currentWeight(CurrentWeightFeature.Action)
        
        /// Stores the actions of the `WeightGoalFeature
        case weightGoal(WeightGoalFeature.Action)
    }
    
}
