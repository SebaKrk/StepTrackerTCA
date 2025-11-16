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
    @Dependency(\.dataAnalyzerClient) var dataAnalyzerClient
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
                
                // MARK: - Internal Actions
                
            case .internal(.startAnalysis):
                return .run { send in
                    await dataAnalyzerClient.startAnalysis()
                }
                
                // MARK: - View Actions
                
            case .view(.onAppear):
                return .send(.internal(.startAnalysis))
                
            case .view(.checkmarkButtonTapped):
                return .run { send in
                    await self.dismiss()
                }
            }
        }
    }
}

// MARK: - Action

extension ReadinessAnalysisFeature {
    @CasePathable
    enum Action: ViewAction {
        
        case `internal`(Internal)
        
        enum Internal {
            /// Triggers the AI analysis via client
            case startAnalysis
        }
        
        case view(View)
        
        enum View {
            /// View appeared - trigger AI analysis
            case onAppear
            
            /// User tapped checkmark to dismiss
            case checkmarkButtonTapped
        }
    }
}

// MARK: - State

extension ReadinessAnalysisFeature {
    
    @ObservableState
    struct State: Equatable {
        
        /// Shared color state used for gradient backgrounds based on readiness level
        @Shared(.inMemory(.readinessLevelColor))
        var color: Color = .clear
    }
}
