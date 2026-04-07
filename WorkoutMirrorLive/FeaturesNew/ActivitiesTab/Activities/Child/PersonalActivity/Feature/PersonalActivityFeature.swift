//
//  PersonalActivityFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 01/02/2026.
//

import ComposableArchitecture
import Foundation
import HealthKit
import IssueReporting
import SharedModels

@Reducer
struct PersonalActivityFeature {
    
    // MARK: - Dependency
    
    @Dependency(\.activityClient) var activityClient
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
                
                // MARK: - Action
                
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
                state.destination = .activityDetails(
                    ActivityDetailsFeature.State(
                        workout: workout,
                        maxHeartRate: state.maxHeartRate ?? 0,
                        primaryZoneInfo: state.zoneInfo[workout.uuid]
                    )
                )
                return .none
                
            case let .view(.showZoneInfo(zone)):
                state.destination = .zoneInfo(
                    HeartRateZoneInfoFeature.State(
                        selectedZone: zone,
                        descriptionIsExpanded: true,
                        displayMode: .singleZone(zone)
                    )
                )
                return .none

            case .view(.refresh):
                return .send(.fetchWorkouts)

            case let .view(.deleteWorkoutSwiped(workout)):
                state.workoutToDelete = workout
                state.deleteAlert = .deleteWorkout
                return .none

            case .alert(.presented(.confirmDelete)):
                let workout = state.workoutToDelete
                state.workoutToDelete = nil
                return .run { [activityClient] send in
                    if let workout {
                        do {
                            try await activityClient.deleteWorkout(workout)
                            await send(.fetchWorkouts)
                        } catch {
                            await send(.deleteFailed)
                        }
                    }
                }

            case .alert(.dismiss):
                state.workoutToDelete = nil
                return .none

            case .deleteFailed:
                state.errorAlert = .cannotDelete
                return .none

            case .errorAlert:
                return .none

                // MARK: - Destination

            case .destination:
                return .none
            }
        }
        .ifLet(\.$deleteAlert, action: \.alert)
        .ifLet(\.$errorAlert, action: \.errorAlert)
        .ifLet(\.$destination, action: \.destination)
    }

}

