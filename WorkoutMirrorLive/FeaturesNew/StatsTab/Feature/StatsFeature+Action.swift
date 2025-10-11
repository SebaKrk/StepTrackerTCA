//
//  StatsFeature+Action.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 26/09/2025.
//

import ComposableArchitecture
import SharedModels

/// Implementation of `StatsFeature` action
extension StatsFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Actions
        
        ///
        case changeSubscriptionTier(SubscriptionTier)
        
        /// Responsible for changing the state of the view.
        case changeViewState(ViewState)
        
        /// Action triggered when the user changes the picker selection.
        ///
        /// - Parameter: `StatsFeatureContext` representing the selected context.
        case selectedPickerChange(StatsFeatureContext)
        
        ///
        case initializeTrainingReadiness
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
                    
            /// Action triggered when the view appears on the screen.
            case viewDidAppear
            
            ///
            case personButtonTapped
            
            ///
            case subscriptionTierButtonTapped(SubscriptionTier)

        }
        
        // MARK: - Destination
        
        /// Action to handle navigation destinations within this feature.
        case destination(PresentationAction<Destination.Action>)
        
        // MARK: - Child
        
        ///
        case trainingReadiness(TrainingReadinessFeature.Action)
    }
    
}
