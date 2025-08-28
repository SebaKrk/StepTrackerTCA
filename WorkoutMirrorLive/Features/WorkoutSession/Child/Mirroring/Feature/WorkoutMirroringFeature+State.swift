//
//  WorkoutMirroringFeature+State.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 17/08/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels

/// Implementation of `WorkoutMirroringFeature` state
extension WorkoutMirroringFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        var elapsedTime: TimeInterval = 0
        
        var pausedElapsedTime: TimeInterval = 0
        
        var isPaused: Bool = false
        
        /// The current metrics of the workout, such as heart rate and active energy burned.
        var workoutMetrics: WorkoutMetrics = WorkoutMetrics(
            averageHeartRate: 0,
            heartRate: 0,
            activeEnergy: 0
        )
        
        ///
        var currentHeartRateZone: HeartRateZone = .resting
        
        ///
        var currentHeartRatePercentage: Int = 0
        
        ///
        var userAge: Int = 37
        
        ///
        var userGender: Gender? = .male
        
        ///
        var mirroringToolBarState: WorkoutMirroringToolBarState = .none
        
        ///
        var isActiveCamera: Bool = false
        
        ///
        var recordIsActive: Bool = false
        
        ///
        var isToolbarHidden: Bool = false
        
        ///
        var workoutSessionState: WorkoutSessionStateTest = .running
        
        // MARK: - Destination
        
        /// destination from WorkoutCreatorFeature
        @Presents var destination: Destination.State?
        
    }
    
}
