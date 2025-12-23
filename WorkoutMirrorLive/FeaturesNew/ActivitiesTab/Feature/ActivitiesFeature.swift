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
                
            case .fetchMaxHeartRate:
                return .run { send in
                    let maxHR = await activityClient.fetchMaxHeartRate()
                    await send(.maxHeartRateFetched(maxHR))
                }
                
            case let .maxHeartRateFetched(maxHR):
                state.maxHeartRate = maxHR
                return .send(.fetchWorkouts)
                
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
                state.zoneInfo = [:]
                
                guard let maxHR = state.maxHeartRate, !workouts.isEmpty else {
                    return .send(.allWorkoutZonesAnalyzed([:]))
                }
                
                return .run { send in
                    var zoneResults: [UUID: PrimaryZoneInfo] = [:]
                    
                    await withTaskGroup(of: (UUID, PrimaryZoneInfo?).self) { group in
                        for workout in workouts {
                            group.addTask {
                                let zoneInfo = try? await activityClient.analyzeWorkoutZones(workout, maxHR)
                                return (workout.uuid, zoneInfo)
                            }
                        }
                        
                        for await (workoutID, zoneInfo) in group {
                            if let zoneInfo {
                                zoneResults[workoutID] = zoneInfo
                            }
                        }
                    }
                    
                    await send(.allWorkoutZonesAnalyzed(zoneResults))
                }
                
            case let .workoutsFetched(.failure(error)):
                dump(error)
                return .send(.changeViewState(.failed))
                
            case let .allWorkoutZonesAnalyzed(zoneInfo):
                state.zoneInfo = zoneInfo
                return .send(.changeViewState(.success))
                
                // MARK: - View Action
                
            case .view(.viewDidAppear):
                return .send(.fetchMaxHeartRate)
                
            case let .view(.changeDays(value)):
                state.days = value
                state.viewState = .loading
                return .send(.fetchWorkouts)
                
            case let .view(.changeSortOption(value)):
                state.sortDescriptors = value
                state.viewState = .loading
                return .send(.fetchWorkouts)
                
            case let .view(.openDetails(workout)):
                // TODO: - Destination
                dump(workout)
                return .none
                
                // MARK: - Destination
                
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
    
}
