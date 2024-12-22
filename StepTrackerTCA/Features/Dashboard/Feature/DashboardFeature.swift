//
//  DashboardFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 21/12/2024.
//

import ComposableArchitecture
import Foundation

@Reducer
struct DashboardFeature {
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
                // MARK: - Actions
            case let .selectedPickerChange(item):
                state.healthMetric = item
                return .none
            
                // MARK: - View actions
            case .view(.viewDidAppear):
                print("view did appear")
                return .none
                
            default: return .none

            }
        }
    }
    
}
