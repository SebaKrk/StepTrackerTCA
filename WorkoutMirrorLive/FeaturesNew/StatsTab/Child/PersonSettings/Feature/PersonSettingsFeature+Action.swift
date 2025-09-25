//
//  PersonSettingsFeature+Action.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 23/09/2025.
//

import ComposableArchitecture
import SharedModels

/// Implementation of `PersonSettingsFeature` action
extension PersonSettingsFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Actions
        
        ///
        case changeAge(Int?)
        
        ////
        case changeSex(BiologicalSex?)
        
        ///
        case changeHeight(HealthKitData?)
        
        ///
        case changeWeight(HealthKitData?)
        
        ///
        case changeRestingHeartRate(HealthKitData?)
        
        ///
        case changeMaxHeartRate(Int? , BiologicalSex?)
        
        ///
        case fetchPersonalData
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
                    
            /// Action triggered when the view appears on the screen.
            case viewDidAppear
            
            ///
            case xMarkButtonTapped
        }
        
        // MARK: - Destination
        
        /// Action to handle navigation destinations within this feature.
        case destination(PresentationAction<Destination.Action>)
    }
}
