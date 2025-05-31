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
    
    // MARK: - Properties
    
    var service: MainServiceAW
    
    // MARK: - Lifecycle
    
    init(service: MainServiceAW = DefaultMainServiceAW()) {
        self.service = service
    }
    
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
                    service.requestAuthorization()
                    return .none
                    
                case let .view(.selectedWorkoutOption(workout)):
                    return .send(.show(workout))
                    
                    // MARK: - Action
                    
                case .openSheet:
                    state.destination = .openSummary(SummaryFeature.State())
                    return .none
                    
                case .openTrainingSheet:
                    state.destination = .openTrainingSummary(TrainingSummaryFeature.State())
                    return .none
                    
                    // MARK: - Destination
                    
                case let .show(workout):
                    switch workout {
                    case .planned:
                        state.destination = .workoutSession(WorkoutSessionFeature.State(selectedWorkout: .crossTraining))
                    case .mirroring:
                        print("mirroring")
                    case .scheduled:
                        print("scheduled")
                        state.destination = .trainingSession(TrainingSessionTabFeature.State(selectedWorkout: .americanFootball))
                    case .free:
                        print("free")
                        state.destination = .openTest(HeartRateFeature.State())
                    }
                    return .none

                case .destination(.presented(.workoutSession(.controlsFeature(.view(.endButtonPressed))))):
                    print("MainFeatureAW - endButtonPressed")
                    return .send(.openSheet)
                     
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
    
