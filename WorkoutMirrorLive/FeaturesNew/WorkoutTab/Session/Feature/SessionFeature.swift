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

    @Dependency(\.sessionClient) var client
    @Dependency(\.dismiss) var dismiss
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
                // MARK: - Action
            case let .sessionViewStateChange(value):
                state.sessionState = value
                if value == .session {
                    return .run { send in
                        for await state in self.client.workoutSessionStateStream() {
                            await send(.controls(.sessionStateUpdated(state)))
                        }
                    }
                }
                return .none

                // MARK: - View Action
            case .view(.viewDidAppear):
                return .run { [workout = state.selectedWorkout] send in
                    try await self.client.selectedWorkout(workout.hkType)
                    await send(.controls(.setWorkoutType(workout)))
                }
                
            case .view(.closeButtonTapped):
                return .run { send in
                    await self.dismiss()
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

/// Implementation of `SessionFeature` action
extension SessionFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Actions
        ///
        case sessionViewStateChange(SessionState)
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
                    
            /// Action triggered when the view appears on the screen.
            case viewDidAppear
            
            ///
            case closeButtonTapped
            
            ///
            case heartRateZoneButtonTapped
            
        }
        
        // MARK: - Destination
        
        /// Action to handle navigation destinations within this feature.
        case destination(PresentationAction<Destination.Action>)
        
        // MARK: - Child
        
        ///
        case countDown(CountDownFeature.Action)
        
        ///
        case live(LiveSessionFeature.Action)
        
        ///
        case controls(ControlsFeature.Action)
        
        ///
        case summary(SummaryFeature.Action)
        
    }
}

/// Implementation of `SessionFeature` state
extension SessionFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        var sessionState: SessionState = .countdown
        
        ///
        var selectedWorkout: WorkoutType
        
        // MARK: - Destination
        
        /// destination from WorkoutFeature
        @Presents var destination: Destination.State?
        
        // MARK: - Child

        ///
        var countDown: CountDownFeature.State = .init()
        
        ///
        var live: LiveSessionFeature.State = .init()
        
        ///
        var controls: ControlsFeature.State = .init()
        
        ///
        var summary: SummaryFeature.State = .init()
    }
    
}

/// Implementation of `SessionFeature` destination
extension SessionFeature {
    
    @Reducer
    enum Destination {
        /// Represents the destination for displaying in `HeartRateZoneInfoFeature`.
        case openHeartRateZoneInfo(HeartRateZoneInfoFeature)
    }
}
