//
//  ActivitiesFeature+Action.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 15/12/2025.
//

import ComposableArchitecture

/// Implementation of `ActivitiesFeature` actions.
extension ActivitiesFeature {
    
    @CasePathable
    enum Action {
        
        // MARK: - Actions
        
        /// Updates the selected tab context (activity/plans).
        case selectedPickerChange(TrainingTabContext)
        
        // MARK: - Child Features
        
        /// Forwards actions to the Personal Activity feature.
        case personalActivity(PersonalActivityFeature.Action)
        
        /// Forwards actions to the Plans feature.
        case plans(PlansFeature.Action)
    }
    
}
