//
//  ActivitiesFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 09/12/2025.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

/// Implementation of `ActivitiesFeature` state.
extension ActivitiesFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        /// The color representing the training readiness level.
        /// Loaded from shared in‑memory storage to keep UI consistent across features.
        @Shared(.inMemory(.readinessLevelColor))
        var color: Color = .gray
        
        /// Selected tab context for filtering workouts.
        var context: TrainingTabContext = .activity
        
        // MARK: - Child Features
        
        /// State for the Personal Activity tab.
        var personalActivity: PersonalActivityFeature.State = PersonalActivityFeature.State()
        
        /// State for the Plans tab.
        var plans: PlansFeature.State = PlansFeature.State()
    }
    
}
