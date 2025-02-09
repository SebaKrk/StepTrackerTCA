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
                    let overheadSquatGoalStart = weightLiftingStatsServices.dateWeeksAgo(10)
                    let overheadSquatGoal = weightLiftingStatsServices.generateDummyGoalData(
                        for: .overheadSquat,
                        target: 100.0,
                        startDate: overheadSquatGoalStart
                    )
                    
                    let cleanAndJerkGoalStart = weightLiftingStatsServices.dateWeeksAgo(5)
                    let cleanAndJerkGoal = weightLiftingStatsServices.generateDummyGoalData(
                        for: .cleanAndJerk,
                        target: 110.0,
                        startDate: cleanAndJerkGoalStart
                    )
                    
                    let goalHistory: [WeightLiftingGoalHistory] = [overheadSquatGoal, cleanAndJerkGoal]
                    
                    let startDateForMeasurements = weightLiftingStatsServices.dateWeeksAgo(12)
                    let dummyData = weightLiftingStatsServices.generateDummyMeasurementData(
                        for: .cleanAndJerk,
                        startDate: startDateForMeasurements,
                        measurementCount: 12,
                        withGoalHistory: goalHistory
                    )
                    
                    weightLiftingStatsServices.printDummyDataAsJSON(for: dummyData)
                    
                    await send(.dummyDataLoaded(dummyData, goalHistory))
                }
                
            case let .dummyDataLoaded(data, goal):
                state.dummyData = data
                state.dummyGoals = goal
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
