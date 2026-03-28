//
//  WorkoutSessionFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 05/08/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels

@Reducer
struct WorkoutSessionFeature {
    
    // MARK: - Dependency

    @Dependency(\.workoutSessionClient) var client
    @Dependency(\.watchConnectivityClient) var watchConnectivityClient
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
                // MARK: - Binding
            case .binding(_):
                return .none
                
                // MARK: - Action
            case let .workoutViewStateChange(viewState):
                state.workoutSessionState = viewState
                
                if viewState == .session {
                    return .send(.runningWorkout)
                }
                return .none
                
            case let .setWorkoutActivityType(workoutActivityType):
                return .run { send in
                    try await self.client.selectedWorkout(workoutActivityType.hkType)
                    //await send(.workoutStart)
                }
            case .runningWorkout:
                return .merge(
                    .run { send in
                        for await metric in await self.client.workoutMetricsStream() {
                            await send(.mirroring(.workoutMetrics(metric)))
                        }
                    },
                    .run { send in
                        await self.watchConnectivityClient.sendWorkoutEvent(
                            .workoutStarted(activityType: 0, elapsedSeconds: 0, maxHeartRate: 0)
                        )
                    },
                    .run { send in
                        for await event in await self.watchConnectivityClient.incomingEventStream() {
                            await send(.watchEventReceived(event))
                        }
                    }
                    .cancellable(id: WorkoutSessionCancelID.watchEventStream)
                )
                
            case .prepareWorkout:
                return .run { send in
                    await send(.workoutViewStateChange(.countdown))
                }
                
            case .endingWorkout:
                return .run { send in
                    await send(.workoutViewStateChange(.summary))
                }
                
                // MARK: - View Action
            case let .view(.changeViewState(viewState)):
                return .send(.workoutViewStateChange(viewState))
                
            case .view(.viewDidAppear):
                if let workout = state.selectedWorkout {
                    return .run { send in
                        await send(.setWorkoutActivityType(workout))
                        await send(.prepareWorkout)
                    }
                } else {
                    print("Bład: Nie ma zaznaczonej ćwiczenia")
                }
                return .none
                
                // MARK: - Child
            case .countDown(.closeView):
                return .send(.workoutViewStateChange(.session))
                
            case .mirroring(.view(.pauseWorkoutButtonTaped)):
                return .run { send in
                    await self.client.togglePause()
                    await self.watchConnectivityClient.sendWorkoutEvent(.workoutPaused)
                }

            case .mirroring(.view(.resumeWorkoutButtonTapped)):
                let elapsed = state.mirroring.pausedElapsedTime
                return .run { [elapsed] send in
                    await self.client.togglePause()
                    await self.watchConnectivityClient.sendWorkoutEvent(.workoutResumed(elapsedSeconds: elapsed))
                }

            case .mirroring(.view(.endWorkoutButtonTapped)):
                return .merge(
                    .cancel(id: WorkoutSessionCancelID.watchEventStream),
                    .run { send in
                        await self.client.endWorkout()
                        await self.watchConnectivityClient.sendWorkoutEvent(.workoutEnded)
                        await send(.endingWorkout)
                    }
                )

            case .watchEventReceived(.hrReading(let bpm, _)):
                let current = state.mirroring.workoutMetrics
                return .send(.mirroring(.workoutMetrics(
                    WorkoutMetrics(
                        averageHeartRate: current.averageHeartRate,
                        heartRate: bpm,
                        activeEnergy: current.activeEnergy
                    )
                )))

            case .watchEventReceived:
                return .none
                
            case .summary(.view(.endWorkoutButtonTapped)):
                return .none
                   
            default:
                return .none
            }
        }
        Scope(state: \.countDown, action: \.countDown) {
            CountDownFeature()
        }
        Scope(state: \.mirroring, action: \.mirroring) {
            WorkoutMirroringFeature()
        }
        Scope(state: \.summary, action: \.summary) {
            WorkoutSummaryFeature()
        }
    }
}

/// Implementation of `WorkoutSessionFeature` action
extension WorkoutSessionFeature {
    
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - Actions
        ///
        case workoutViewStateChange(WorkoutSessionState)
        
        ///
        case setWorkoutActivityType(WorkoutType)
        
        ///
        case prepareWorkout
        
        ///
        case endingWorkout
        
        ///
        case runningWorkout

        /// Received when the paired Apple Watch sends a `WatchWorkoutEvent` during an active session.
        case watchEventReceived(WatchWorkoutEvent)

        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            /// Action triggered when the view appears on the screen.
            case viewDidAppear
            
            ///
            case changeViewState(WorkoutSessionState)
        }
        
        // MARK: - Child
        
        ///
        case countDown(CountDownFeature.Action)
        
        ///
        case mirroring(WorkoutMirroringFeature.Action)
        
        ///
        case summary(WorkoutSummaryFeature.Action)
    }
    
    
}

// MARK: - Cancel IDs

/// Cancel identifiers used by `WorkoutSessionFeature` long-running effects.
///
/// Declared outside the `@Reducer` to avoid `@MainActor` isolation
/// that would prevent conformance to `Sendable` (required by `cancellable(id:)`).
private nonisolated enum WorkoutSessionCancelID: Hashable, Sendable {

    /// Identifies the stream listening for incoming Watch workout events.
    case watchEventStream

}

/// Implementation of `WorkoutSessionFeature` state
extension WorkoutSessionFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        ///
        var workoutSessionState: WorkoutSessionState = .start
        
        ///
        var selectedWorkout: WorkoutType?
        
        // MARK: - Child

        ///
        var countDown: CountDownFeature.State = .init()
        
        ///
        var mirroring: WorkoutMirroringFeature.State = .init()
        
        ///
        var summary: WorkoutSummaryFeature.State = .init()
    }
    
}
