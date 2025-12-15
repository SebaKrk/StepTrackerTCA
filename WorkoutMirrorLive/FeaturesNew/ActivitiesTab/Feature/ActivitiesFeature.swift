//
//  ActivitiesFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 20/08/2025.
//

import ComposableArchitecture
import Foundation
import HealthKit
import SharedModels

@Reducer
struct ActivitiesFeature {
    
    // MARK: - Dependency
    
    @Dependency(\.activityClient) var activityClient
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
                // MARK: - Action
                
            case let .selectedPickerChange(value):
                state.context = value
                return .none
                
            case let .changeViewState(value):
                state.viewState = value
                return .none
                
            case .fetchWorkouts:
                let days = state.days  
                let descriptors = state.sortDescriptors
                return .run { send in
                    await send(.workoutsFetched(
                        Result {
                            try await activityClient.fetchWorkouts(days, descriptors)
                        }
                    ))
                }
                
            case let .workoutsFetched(.success(workouts)):
                state.workouts = workouts
                return .send(.changeViewState(.success))
                
            case let .workoutsFetched(.failure(message)):
                dump(message)
                return .send(.changeViewState(.failed))
                
                // MARK: - View Action
                
            case .view(.viewDidAppear):
                return .send(.fetchWorkouts)
                
            case .view(.changeDays(_)):
                return .none
                
            case let.view(.changeSortOption(value)):
                state.sortDescriptors = value
                return .send(.fetchWorkouts)
                
                // MARK: - Destination
                
            case .destination(_):
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}


