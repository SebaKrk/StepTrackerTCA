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
        Reduce {
            state,
            action in
            switch action {
                // MARK: - Actions
                
            case .navigateToHealthDataList:
                return .none
                
                // MARK: - View actions
                
            case .view(.viewDidAppear):
                print("view did appear")
                return .none
                
                // MARK: - View destination
                
            case .view(.addDataButtonPressed):
                state.destination = .openAddMetricData(
                    AddMetricDataFeature.State(healthMetric: state.healthMetric)
                )
                return .none
                
            default: return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
    
}
