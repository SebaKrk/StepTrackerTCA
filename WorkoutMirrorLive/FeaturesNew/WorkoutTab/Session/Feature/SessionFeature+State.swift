//
//  SessionFeature+State.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 21/09/2025.
//

import ComposableArchitecture
import SharedModels

/// Implementation of `SessionFeature` state
extension SessionFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        ///
        var sessionState: SessionState = .countdown
        
        ///
        var selectedWorkout: WorkoutType
                
        // MARK: - Destination
        
        /// destination from WorkoutFeature
        @Presents var destination: Destination.State?
        
        // MARK: - Child

        ///
        var countDown: CountDownFeature.State = .init()
        
        ///
        var live: LiveSessionFeature.State = .init()
        
        ///
        var controls: ControlsFeature.State = .init()
        
        ///
        var summary: SummaryFeature.State = .init()
    }
    
}
