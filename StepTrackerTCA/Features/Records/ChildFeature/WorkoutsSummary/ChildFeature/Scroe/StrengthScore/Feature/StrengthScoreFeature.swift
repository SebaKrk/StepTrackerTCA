//
//  StrengthScoreFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 09/03/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct StrengthScoreFeature {
    
    // MARK: - Properties
    
    var service: StrengthScoreService
    
    // MARK: - LifeCycle
    
    init(service: StrengthScoreService = DefaultStrengthScoreService()) {
        self.service = service
    }
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
                // MARK: - Actions
            case .groupedWorkouts:
                state.groupedWorkoutsData = service.groupWorkoutsByMovement(state.data)
                dump( state.groupedWorkoutsData )
                return .none
                
            case .findBestWorkout:
                state.bestWorkout = service.findBestWorkout(from: state.data)
                return .none

                // MARK: - View Actions
            case .view(.viewDidAppear):
                return .run { send in
                    await send(.groupedWorkouts)
                    await send(.findBestWorkout)
                }
                
                // MARK: - Destination
            case .destination:
                return .none
            }
        }
    }
    
}
