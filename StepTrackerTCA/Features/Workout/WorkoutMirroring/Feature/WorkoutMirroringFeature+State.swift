//
//  WorkoutMirroringFeatureState.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 23/06/2025.
//

import ComposableArchitecture
import SwiftUI
import SharedModels

/// Implementation of `WorkoutMirroringFeature` state
extension WorkoutMirroringFeature {
    
    @ObservableState
    struct State {
        
        var workoutMetrics: WorkoutMetrics = WorkoutMetrics(
            averageHeartRate: 0,
            heartRate: 0,
            activeEnergy: 0
        )
        
        var sessionState: Bool = false
        
        var currentHeartRateZone: HeartRateZone = .resting
        
        var currentHeartRatePercentage: Int = 0
        
        var userAge: Int = 37
        
        var userGender: Gender? = .male
        
        // MARK: - Destination
        
        /// destination from ActivityFeature
        @Presents var destination: Destination.State?
    }
}
