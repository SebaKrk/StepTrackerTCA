//
//  SessionFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 27/08/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels

@Reducer
struct SessionFeature {
    
    // MARK: - Dependency

    @Dependency(\.sessionClient) var sessionClient
    @Dependency(\.personCalculatorClient) var calculator
    @Dependency(\.personalDataClient) var personalDataClient
    
    @Dependency(\.dismiss) var dismiss
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
                // MARK: - Action
            case let .sessionViewStateChange(value):
                state.sessionState = value
                if value == .session {
                    let initialState = WorkoutSessionActivityAttributes.ContentState(
                        heartRate: 0,
                        heartRateZone: .resting,
                        heartRatePercentage: 0,
                        activeEnergy:  0,
                        maxHeartRate: 0,
                        averageHeartRate: 0
                    )
                    
                    return .merge(
                        .run { send in
                            for await state in await self.sessionClient.workoutSessionStateStream() {
                                await send(.controls(.sessionStateUpdated(state)))
                            }
                        },
                        .send(.live(.liveActivity(.workout(.start(workoutName: state.selectedWorkout.title,initialState: initialState)))))
                    )
                } else if value == .summary {
                    return .send(.live(.liveActivity(.workout(.stop))))
                }
                return .none

            case .makeCalculationForSession:
                return .run { send in
                    let age = try await personalDataClient.getAge()
                    let sex = try await personalDataClient.getBiologicalSex()
                    
                    guard let age = age, let sex = sex else {
                        // rzucic blad ze musi byc ustawiony wiek i plec ?
                        return
                    }
                    
                    let maxHR = await calculator.calculateMaxHeartRate(age, sex)
                    await send(.setMaxHR(maxHR))
                }
                
            case let .setMaxHR(value):
                return .send(.live(.setupMaxHeartRate(value)))
                            
                
                // MARK: - View Action
            case .view(.viewDidAppear):
                return .run { [workout = state.selectedWorkout] send in
                    try await self.sessionClient.selectedWorkout(workout.hkType)
                    
                    await send(.controls(.setWorkoutType(workout)))
                    await send(.makeCalculationForSession)
                }
 
            case .view(.heartRateZoneButtonTapped):
                state.destination = .openHeartRateZoneInfo(HeartRateZoneInfoFeature.State())
                return .none

                // MARK: - Destination
            case .destination(_):
                return .none
                
                // MARK: - Child
            case .countDown(.closeView):
                return .send(.sessionViewStateChange(.session))
                
            case .controls(.view(.endWorkoutButtonTapped)):
                return .send(.sessionViewStateChange(.summary))
                
            case .summary(.view(.endWorkoutButtonTapped)):
                return .run { send in
                    await self.dismiss()
                }
                
            case .countDown(_):
                return .none
            case .live(_):
                return .none
            case .controls(_):
                return .none
            case .summary(_):
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
        Scope(state: \.countDown, action: \.countDown) {
            CountDownFeature()
        }
        Scope(state: \.live, action: \.live) {
            LiveSessionFeature()
        }
        Scope(state: \.controls, action: \.controls) {
            ControlsFeature()
        }
        Scope(state: \.summary, action: \.summary) {
            SummaryFeature()
        }
    }
}


