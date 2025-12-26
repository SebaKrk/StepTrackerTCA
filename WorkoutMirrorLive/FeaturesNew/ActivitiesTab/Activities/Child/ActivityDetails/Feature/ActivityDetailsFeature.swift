//
//  ActivityDetailsFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 26/12/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels
import SwiftUI
import HealthKit

@Reducer
struct ActivityDetailsFeature {
    
    // MARK: - Dependency
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
            case .view(.viewDidAppear):
                return .none
            }
        }
    }
    
}

/// Implementation of `ActivityDetailsFeature` actions.
extension ActivityDetailsFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Actions
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            /// Triggered when the view appears on screen.
            case viewDidAppear
        }
        
    }
}

/// Implementation of `ActivityDetailsFeature` state.
extension ActivityDetailsFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        /// The color representing the training readiness level.
        /// Loaded from shared in‑memory storage to keep UI consistent across features.
        @Shared(.inMemory(.readinessLevelColor))
        var color: Color = .clear
        
        ///
        var workout: HKWorkout
        
    }
    
}
