//
//  WorkoutSummaryFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 13/08/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels
//import HealthKit

nonisolated enum WorkoutSummaryFeatureCancelID: Hashable, Sendable {
    case sessionStateListener
    case retry
}

@Reducer
struct WorkoutSummaryFeature {
    
    // MARK: - Dependency
    
    @Dependency(\.workoutSummaryClient) var client
    @Dependency(\.dismiss) var dismiss
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        CombineReducers {
            BindingReducer()
            Reduce { state, action in
                switch action {
                    
                    // MARK: - Binding
                case .binding(_):
                    return .none
                    
                    // MARK: - Action
                case let .changeViewState(viewState):
                    state.viewState = viewState
                    return .none
                    
                case .checkWorkoutSummary:
                    return .run { send in
                        let summary = await client.getWorkoutSummary()
                        await send(.workoutSummaryLoaded(summary))
                    }
                    
                case let .workoutSummaryLoaded(summary):
                    state.summary = summary

                    if summary.workout != nil {
                        state.viewState = .successfullyLoaded
                        // Sprzątnij ewentualny retry, jeśli jeszcze chodzi
                        return .cancel(id: WorkoutSummaryFeatureCancelID.retry)
                    } else {
                        state.viewState = .loading
                        // Delikatny retry z krótkim sleepem i cancelInFlight,
                        // żeby nie uruchamiać wielu retry naraz.
                        return .run { send in
                            try? await Task.sleep(for: .milliseconds(3000))
                            await send(.checkWorkoutSummary)
                        }
                        .cancellable(id: WorkoutSummaryFeatureCancelID.retry, cancelInFlight: true)
                    }
                    
                    // MARK: - View Action
                case .view(.viewDidAppear):
                        return .run { send in
                            await send(.checkWorkoutSummary)
                        }
                    
                case .view(.endWorkoutButtonTapped):
                    return .run { send in
                        await self.dismiss()
                    }
//                    return .merge(
//                        .cancel(id: WorkoutSummaryFeatureCancelID.sessionStateListener),
//                        .cancel(id: WorkoutSummaryFeatureCancelID.retry)
//                        
//                    )
//                    
                    // zastanow sie czy nie gdzies inedziej tzn wczesniej
                    // jak robie zamkiecie i usuwam caly destination to ta akacja jeszcze leci co powoduje blad
                    // narazie dalem ja do endWorkoutButtonTapped
                case .view(.viewDidDisappear):
                    return .merge(
                        .cancel(id: WorkoutSummaryFeatureCancelID.sessionStateListener),
                        .cancel(id: WorkoutSummaryFeatureCancelID.retry)
                    )
                }
            }
        }
    }
    
}

/// Implementation of `WorkoutSummaryFeature` action
extension WorkoutSummaryFeature {
    
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - Actions
        /// Responsible for changing the state of the view.
        case changeViewState(WorkoutSummaryState)
        
        /// Initiates the workout summary check process. If the workout is ready, transitions to a loaded state; otherwise, begins a retry sequence.
        case checkWorkoutSummary
        
        /// Called when the workout summary has been successfully loaded.
        case workoutSummaryLoaded(WorkoutSummary)
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            /// Action triggered when the view appears on the screen.
            case viewDidAppear
            
            ///
            case viewDidDisappear
            
            case endWorkoutButtonTapped
        }
    }
}

/// Implementation of `WorkoutSummaryFeature` state
extension WorkoutSummaryFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        ///
        var viewState: WorkoutSummaryState = .loading
        
        ///
        var summary: WorkoutSummary? = nil
    }
    
}



//                    return .merge(
//                        .run { send in
//                            print("📌 [WorkoutSummaryFeature] viewDidAppear → wysyłam pierwszy checkWorkoutSummary (optymistyczny)")
//                            await send(.checkWorkoutSummary)
//                        },
//                        .run { send in
//                            print("📌 [WorkoutSummaryFeature] Rozpoczynam nasłuch sessionStateStream()")
//                            for await state in await client.sessionStateStream() {
//                                print("💫 [WorkoutSummaryFeature] Otrzymano sessionState = \(state)")
//                                if state == .ended {
//                                    print("✅ [WorkoutSummaryFeature] sessionState == .ended → wysyłam checkWorkoutSummary")
//                                    await send(.checkWorkoutSummary)
//                                    break
//                                }
//                            }
//                            print("🛑 [WorkoutSummaryFeature] Nasłuch sessionStateStream() zakończony")
//                        }
//                            .cancellable(id: WorkoutSummaryFeatureCancelID.sessionStateListener)
//                    )
