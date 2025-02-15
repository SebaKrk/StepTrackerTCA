//
//  WeightLiftingStatsFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 08/02/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct WeightLiftingStatsFeature {
    
    // MARK: - Dependencies
    
    let weightLiftingStatsServices: WeightLiftingStatsServices

    // MARK: - Livecycle
    
    init(service: WeightLiftingStatsServices) {
        self.weightLiftingStatsServices = service
    }
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce {
            state,
            action in
            switch action {
                
                // MARK: - Actions
            case .getDummyData:
                return .run { send in
                    let dummyResult = await weightLiftingStatsServices.getDummyData()
                    await send(.dummyDataLoaded(dummyResult.dummyData, dummyResult.goalHistory))
                }
                
            case let .dummyDataLoaded(data, goal):
                state.dummyData = data
                state.dummyGoals = goal
                state.data = weightLiftingStatsServices.mapData(history: state.dummyGoals, measurements: state.dummyData)
                return .none
                
                // MARK: - View Actions
                
            case .view(.viewDidAppear):
                return .send(.getDummyData)
            
            case .view(.navigationButtonTapped):
                return .send(.show)
                
                // MARK: - Destination
                
            case .show:
                state.destination = .open(WeightLiftingGoalsFeature.State())
                return .none
                
            case .destination(_):
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
    
}
