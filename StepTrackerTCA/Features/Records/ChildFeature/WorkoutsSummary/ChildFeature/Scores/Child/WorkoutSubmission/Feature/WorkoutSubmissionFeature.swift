//
//  WorkoutSubmissionFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 12/04/2025.
//

import ComposableArchitecture

@Reducer
struct WorkoutSubmissionFeature {
    
    // MARK: - Dependency
    
    @Dependency(\.workoutSubmissionStrategyFactory) var strategyFactory
    
    @Dependency(\.dismiss) var dismiss
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state,action in
            switch action {
                
            case .addValue:
                return .run { [service = state.service, workoutType = state.workoutType] send in
                    let strategy = strategyFactory.strategy(for: service)
                    do {
                        try await strategy.submit(workout: workoutType , movement: "clean", date: .now, value: "123", unit: "kg")
                    } catch {
                        
                    }
                }
                
            case .view(.add):
                return .run { send in
                    await send(.addValue)
                }
                
            case .view(.viewDidAppear):
                print("WorkoutSubmissionFeature")
                return .none
            }
        }
    }
}
