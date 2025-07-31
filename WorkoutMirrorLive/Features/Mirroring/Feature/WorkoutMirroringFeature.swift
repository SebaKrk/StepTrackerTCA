//
//  WorkoutMirroringFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 31/07/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct WorkoutMirroringFeature {
    
    // MARK: - Dependency
    
    @Dependency(\.dismiss) var dismiss
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        
        Reduce { state, action in
            switch action {
                
                // MARK: - Action
                
                // MARK: - View Action
            case .view(.xMarkButtonTapped):
                return .run { send in
                    await self.dismiss()
                }
                
            case .view(.viewDidAppear):
                return .none
            }
        }
    }
}

/// Implementation of `WorkoutMirroringFeature` action
extension WorkoutMirroringFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            ////
            case xMarkButtonTapped
            
            /// Action triggered when the view appears on the screen.
            case viewDidAppear
        }
    }
}

/// Implementation of `WorkoutMirroringFeature` state
extension WorkoutMirroringFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
    }
    
}
