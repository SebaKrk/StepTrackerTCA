//
//  PersonDataFeature+State.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 23/01/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `PersonDataFeature` state
extension PersonDataFeature {
    
    @ObservableState
    struct State {
        // MARK: - Properties
        
        
        // MARK: - Destination
        
        /// destination from ActivityFeature
        @Presents var destination: Destination.State?
    }
}

