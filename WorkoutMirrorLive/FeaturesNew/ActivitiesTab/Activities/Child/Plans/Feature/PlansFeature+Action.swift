//
//  PlansFeature+Action.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 01/02/2026.
//

import ComposableArchitecture
import Foundation

extension PlansFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        case view(View)
        
        @CasePathable
        enum View {
            
            /// Called when view appears.
            case viewDidAppear
            
            /// Called when user taps "Add Plan" button.
            case addPlanTapped
        }
        
        // MARK: - Destination
        
        /// Handles navigation destinations within this feature.
        case destination(PresentationAction<Destination.Action>)
    }
    
}
