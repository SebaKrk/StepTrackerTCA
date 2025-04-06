//
//  MovementDetailsFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 12/03/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct MovementDetailsFeature {
    
    // MARK: - Dependencies
    
    let services: MovementDetailsFeatureServices
    
    // MARK: - Livecycle
    
    init(service: MovementDetailsFeatureServices = DefaultMovementDetailsFeatureServices()) {
        self.services = service
    }
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
            case .filterByMovement:
                return .run { [groupedMovement = state.selectedMovement,  movement = state.movement] send in
                    let filteredMovement = services.filterGroupedMovementByExercise(groupedMovement, movementName: movement)
                    await send(.update(filteredMovement))
                }
                
            case let .update(groupedMovement):
                state.filteredMovement = groupedMovement
                
                return .run { send in
                    await send(.checkGoals(groupedMovement))
                }
                
                
            case let .checkGoals(groupedMovement):
                guard let goals = groupedMovement.goals, goals.count >= 2 else {
                    return .none
                }
                return .run { [movementName = state.movement] send in
                    let goalIntervals = services.generateGoalIntervals(workoutGoals: goals, movementName: movementName)
                    await send(.updateGoalInterval(goalIntervals))
                }
                
            case let .updateGoalInterval(goalIntervals):
                state.goalIntervals = goalIntervals
                return .none
                
            case .view(.viewDidAppear):
                return .run { send in
                    await send(.filterByMovement)
                }
            }
        }
    }
    
    /// A structure representing an interval between workout goals.
    ///
    /// This structure is defined as a nested type within `MovementDetailsFeature` and is intended
    /// to be used exclusively by this feature for displaying progress and intervals on the chart.
    ///
    /// - Note: It is not intended to be shared outside of `MovementDetailsFeature`.
    struct GoalInterval: Equatable {
        
        /// The starting date of the interval.
        let start: Date
        
        /// The ending date of the interval.
        let end: Date
        
        /// The value associated with the interval (e.g., weight lifted, distance covered).
        let value: Double
    }
    
}
