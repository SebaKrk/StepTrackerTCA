//
//  WorkoutMirroringFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 12/06/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels
import HealthHub

@Reducer
struct WorkoutMirroringFeature {
    
    // MARK: - Properties
    
    let service: TrainingCalculationsService
    
    // MARK: - Dependency
    
    @Dependency(\.workoutMirroringClient) var client

    // MARK: - Lifecycle
    
    init(service: TrainingCalculationsService = DefaultTrainingCalculationsService()) {
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
                    
                case .checkSessionState:
                   let sessionState = client.sessionState()
                   print("🔴 Checking session state: \(sessionState)")
                   
                   state.sessionState = sessionState
                   
                   if state.sessionState {
                       print("🔴 Session is active - sending startMirroringWorkout")
                       return .send(.startMirroringWorkout)
                   } else {
                       print("🔴 Session is NOT active - no action taken")
                   }
                   return .none
                    
                case let .workoutMetrics(data):
                    state.workoutMetrics = data
                    print("heartRate: \(data.heartRate)")
                    
                    let maxHR = service.calculateMaxHeartRate(age: state.userAge, gender: state.userGender)
                    let zone = service.calculateHeartRateZone(current: Int(data.heartRate), max: maxHR)
                    let percentage = service.calculateHeartRatePercentage(current: Int(data.heartRate), max: maxHR)
                     
                    state.currentHeartRateZone = zone
                    state.currentHeartRatePercentage = percentage
                    
                    return .none
                    
                case .startMirroringWorkout:
                    print("🔴 Starting mirroring workout - creating stream...")
                    return .run { send in
                        print("🔴 Stream created, waiting for metrics...")
                        for await metrics in client.workoutMetricsStream() {
                            print("🔴 Received metrics in stream: HR=\(metrics.heartRate)")
                            await send(.workoutMetrics(metrics))
                        }
                    }
                    
                    // MARK: - View Actions
                case .view(.viewDidAppear):
                    return .send(.checkSessionState)
                    
                case .view(.viewWillDisappear):
                    return .cancel(id: CancelID.workoutMetricsStream)
                }
            }
        }
    }
    
    private enum CancelID {
        case workoutMetricsStream
    }
}
