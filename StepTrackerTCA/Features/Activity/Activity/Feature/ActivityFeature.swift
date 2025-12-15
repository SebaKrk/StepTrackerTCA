//
//  ActivityFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 12/01/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct ActivityFeature {
    
    // MARK: - Properties
    
    var service: DefaultActivityFeatureService
    
    // MARK: - Lifecycle
    
    init(service: DefaultActivityFeatureService = DefaultActivityFeatureService()) {
        self.service = service
    }
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        CombineReducers {
            BindingReducer()
            Reduce { state, action in
                switch action {
                    
                    // MARK: - Binding
                case .binding(_):
                    return .none
                    
                    // MARK: - Actions
                    
                case let .selectedPickerChange(period):
                    state.activityPeriod = period
                    return .none
                    
                case .fetchHealthData:
                    return .run { send in
                        await send(.updateHKData(Result {
                            try await service.getWorkoutData()
                        }))
                    }
                case let .updateHKData(.success(data)):
                    state.workouts = data
                    dump(data)
                    return .none
                    
                case let .updateHKData(.failure(error)):
                    print("❌ Failed to fetchHK data: \(error.localizedDescription)")
                    return .none
                    
                    
                    // MARK: - View Actions
                 
                case let .view(.tapWorkout(workout)):
                    return .send(.workoutSelected(workout))
                    
                case let .view(.tapHKWorkout(workout)):
                    return .send(.HKWorkoutSelected(workout))
                    
                case .view(.viewDidAppear):
                    return .run { send in
                        await send(.fetchHealthData)
                    }
                    
                // MARK: - Destination
                    
                case let .workoutSelected(workout):
                    state.selectedWorkout = workout
                    if let workout {
                        return .send(.show(workout))
                    }
                    return .none
                    
                case let .HKWorkoutSelected(workout):
                    state.selectedHKWorkout = workout
                    if let workout {
                        return .send(.showHR(workout))
                    }
                    return.none
                    
                case let .show(workout):
                    state.destination = .detailItem(ActivityDetailsFeature.State(workout: workout))
                    return .none
                    
                case let .showHR(workout):
                    state.destination = .heartRateDetails(HeartRateDetailsFeature.State(workout: workout))
                    return .none
                    
                case .destination:
                    return .none
                }
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
    
}
