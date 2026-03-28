//
//  SessionFeature+Action.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 21/09/2025.
//

import ComposableArchitecture
import SharedModels

/// Implementation of `SessionFeature` action
extension SessionFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Actions
        ///
        case sessionViewStateChange(SessionState)
        
        ///
        case makeCalculationForSession
        
        
        case setMaxHR(Int)

        /// Fired once per second by the internal clock effect while the workout is running.
        ///
        /// Reads `state.controls.elapsedTime` and sends `.workoutTick` to Watch.
        case watchTickEffect

        /// Received when the paired Apple Watch sends a `WatchWorkoutEvent` during an active session.
        case watchEventReceived(WatchWorkoutEvent)

        // MARK: - View Actions
        
        case view(View)
        
        enum View {
                    
            /// Action triggered when the view appears on the screen.
            case viewDidAppear
            
            ///
            //case closeButtonTapped
            
            ///
            case heartRateZoneButtonTapped
            
            /// Timer button tapped in toolbar
            case timerButtonTapped
            
        }
        
        // MARK: - Destination
        
        /// Action to handle navigation destinations within this feature.
        case destination(PresentationAction<Destination.Action>)
        
        // MARK: - Child
        
        ///
        case countDown(CountDownFeature.Action)
        
        ///
        case live(LiveSessionFeature.Action)
        
        ///
        case controls(ControlsFeature.Action)
        
        ///
        case summary(SummaryFeature.Action)
        
    }
    
}
