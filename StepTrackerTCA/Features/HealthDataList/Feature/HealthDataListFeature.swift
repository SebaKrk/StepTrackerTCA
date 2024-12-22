//
//  HealthDataListFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 22/12/2024.
//

import ComposableArchitecture
import Foundation

@Reducer
struct HealthDataListFeature {
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                // MARK: - Actions
                
            case .navigateToHealthDataList:
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
