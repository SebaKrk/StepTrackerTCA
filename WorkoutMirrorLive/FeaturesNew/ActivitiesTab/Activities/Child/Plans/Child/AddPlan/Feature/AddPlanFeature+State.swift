//
//  AddPlanFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 01/02/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

extension AddPlanFeature {
    
    @ObservableState
    struct State: Equatable {
        
        // MARK: - Properties
        
        /// The color representing the training readiness level.
        @Shared(.inMemory(.readinessLevelColor))
        var color: Color = .clear
        
        /// Current view state.
        var viewState: ViewState = .success
    }
    
}
