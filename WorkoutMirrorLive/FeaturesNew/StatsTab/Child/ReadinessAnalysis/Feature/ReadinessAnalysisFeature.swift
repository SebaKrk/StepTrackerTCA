//
//  ReadinessAnalysisFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 15/11/2025.
//

import ComposableArchitecture
import SwiftUI
import SharedModels

@Reducer
struct ReadinessAnalysisFeature {
    
    // MARK: - Dependency
    @Dependency(\.dismiss) var dismiss
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
                // MARK: - Internal Action
                // MARK: - View Action
                
            case .view(.checkmarkButtonTapped):
                return .run { send in
                    await self.dismiss()
                }
            }
        }
    }
}

/// Implementation of `ReadinessAnalysisFeature` action
extension ReadinessAnalysisFeature {
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Internal Actions
        
        case `internal`(Internal)
        
        enum Internal {
            
        }
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            ///
            case checkmarkButtonTapped
        }
    }
    
}

/// State container for `ReadinessAnalysisFeature`.
extension ReadinessAnalysisFeature {
    
    @ObservableState
    struct State {
        
        /// Shared color state used for gradient backgrounds based on readiness level
        @Shared(.inMemory(.readinessLevelColor))
        var color: Color = .clear
        
        // MARK: - Properties
    }
}
