//
//  SummaryFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 30/08/2025.
//

import ComposableArchitecture
import SharedModels
import Foundation

@Reducer
struct SummaryFeature {
    
    // MARK: - Dependency
    
    @Dependency(\.sessionClient) var client
    @Dependency(\.dismiss) var dismiss
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
                // MARK: - Action
            case let .changeViewState(viewState):
                state.viewState = viewState
                return .none
                
            case .checkSummary:
                return .run { send in
                    let summary = await client.getWorkoutSummary()
                    await send(.summaryLoaded(summary))
                }
                
            case let .summaryLoaded(summary):
                state.summary = summary
                
                if summary.workout != nil {
                    state.viewState = .successfullyLoaded
                    return .cancel(id: SummaryFeatureCancelID.retry)
                } else {
                    state.viewState = .loading
                    return .run { send in
                        try? await Task.sleep(for: .milliseconds(3000))
                        await send(.checkSummary)
                    }
                    .cancellable(id: SummaryFeatureCancelID.retry, cancelInFlight: true)
                }
                
                // MARK: - View Action
            case .view(.viewDidAppear):
                return .run { send in
                    await send(.checkSummary)
                }
                
            case .view(.endWorkoutButtonTapped):
                return .run { send in
                    await self.dismiss()
                }
                
            case .view(.viewDidDisappear):
                return .merge(
                    .cancel(id: SummaryFeatureCancelID.sessionStateListener),
                    .cancel(id: SummaryFeatureCancelID.retry)
                )
            }
        }
    }
}

/// Implementation of `SummaryFeature` action
extension SummaryFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Actions
        
        /// Responsible for changing the state of the view.
        case changeViewState(SummaryState)
        
        /// Initiates the workout summary check process. If the workout is ready, transitions to a loaded state; otherwise, begins a retry sequence.
        case checkSummary
        
        /// Called when the workout summary has been successfully loaded.
        case summaryLoaded(WorkoutSummary)
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            /// Action triggered when the view appears on the screen.
            case viewDidAppear
            
            ///
            case viewDidDisappear
            
            ///
            case endWorkoutButtonTapped
        }
    }
}

/// Implementation of `SummaryFeature` state
extension SummaryFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        ///
        var viewState: SummaryState = .loading
        
        ///
        var summary: WorkoutSummary? = nil
    }
    
}

nonisolated enum SummaryFeatureCancelID: Hashable, Sendable {
    case sessionStateListener
    case retry
}
