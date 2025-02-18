//
//  ExerciseDetailsFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 16/02/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct ExerciseDetailsFeature {
    
    let services: MockWeightLiftingData = MockWeightLiftingData()
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                // MARK: - Actions
                
            case let .update(data, goal):
                state.chartData = data
                state.goalHistory = goal
                state.minValue = data.map { $0.value }.min() ?? 0
                state.goal = 105
                return .none
                
                
                // MARK: - View Actions
                
            case .view(.viewDidAppear):
                return .run { send in
                    let (data, goals) = await MockWeightLiftingData.getChartDataForCleanAndJerk()
                    await send(.update(data, goals))
                }
            }
        }
    }
    
}

import ComposableArchitecture
import Foundation

/// Implementation of `ExerciseDetailsFeature` action
extension ExerciseDetailsFeature {
    
    @CasePathable
    enum Action: ViewAction {
        // MARK: - Actions
        
        case update([WeightLiftingMeasurement], [WeightLiftingGoalHistory])
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            case viewDidAppear
        }
    }
    
}


import ComposableArchitecture
import Foundation

/// Implementation of `ExerciseDetailsFeature` state
extension ExerciseDetailsFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        var chartData: [WeightLiftingMeasurement] = []
        var goalHistory: [WeightLiftingGoalHistory] = []
        var minValue: Double = 0
        var goal: Double? = nil
        
    }
}
