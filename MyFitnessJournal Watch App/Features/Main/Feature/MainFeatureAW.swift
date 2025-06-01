//
//  MainFeatureAW.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 19/05/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct MainFeatureAW {
    
    // MARK: - Dependency
    
    @Dependency(\.authorizationClientAW) var client
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        CombineReducers {
            BindingReducer()
            Reduce { state, action in
                switch action {
                   
                    // MARK: - Binding Action
                case .binding(_):
                    return .none

                    // MARK: - View Action
                case .view(.viewDidAppear):
                    client.requestAuthorization()
                    return .none
                    
                case let .view(.selectedWorkoutOption(workout)):
                    return .send(.show(workout))
                    
                    // MARK: - Action
                    
                case .openTrainingSheet:
                    state.destination = .openTrainingSummary(TrainingSummaryFeature.State())
                    return .none
                    
                    // MARK: - Destination
                    
                case let .show(workout):
                    switch workout {
                    case .planned:
                        print("planned")
                    case .mirroring:
                        print("mirroring")
                    case .scheduled:
                        print("scheduled")
                    case .free:
                        print("free")
                        state.destination = .trainingSession(TrainingSessionTabFeature.State(selectedWorkout: .americanFootball))
                    }
                    return .none
                     
                case .destination(.presented(.trainingSession(.controls(.view(.endButtonPressed))))):
                    return .send(.openTrainingSheet)
                    
                default:
                    return .none
                }
            }
        }
        .ifLet(\.$destination, action: \.destination)
        
        //._printChanges()
    }
    
}
    
