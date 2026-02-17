//
//  PlansFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 01/02/2026.
//

import ComposableArchitecture
import Foundation

@Reducer
struct PlansFeature {
    
    // MARK: - Body
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                // MARK: - View Action
                
            case .view(.viewDidAppear):
                
                return .none
                
            case .view(.addPlanTapped):
                state.destination = .addPlan(AddPlanFeature.State())
                return .none
                
                // MARK: - Destination
                
            case .destination(.presented(.addPlan(.destination(.presented(.scanPlan(.destination(.presented(.workoutPreview(.view(.saveButtonTapped)))))))))):
                state.destination = nil
                return .none 
                
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
    
}
