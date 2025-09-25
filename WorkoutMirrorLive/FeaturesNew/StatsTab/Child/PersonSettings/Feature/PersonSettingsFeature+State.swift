//
//  PersonSettingsFeature+State.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 23/09/2025.
//

import ComposableArchitecture

/// Implementation of `PersonSettingsFeature` state
extension PersonSettingsFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        var age: String = "-"
        
        var sex: String = "-"
        
        var height: String = "-"
        
        var weight: String = "-"
        
        var restingHeartRate: String = "-"
        
        var maxHR: String = "-"
        
        // MARK: - Destination
        
        /// destination from PersonSettingsFeature
        @Presents var destination: Destination.State?
    }
    
}
