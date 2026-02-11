//
//  AddPlanFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 01/02/2026.
//

import ComposableArchitecture
import Foundation

@Reducer
struct AddPlanFeature {
    
    // MARK: - Body
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

                // MARK: - View Action

            case .view(.viewDidAppear):
                return .none

            case .view(.dismissTapped):
                return .none

            case .view(.scanPlanTapped):
                state.destination = .scanPlan(ScanPlanFeature.State())
                return .none

            case .view(.manualEntryTapped):
                // TODO: - Open manual entry form
                return .none

                // MARK: - Destination

            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
    
}
