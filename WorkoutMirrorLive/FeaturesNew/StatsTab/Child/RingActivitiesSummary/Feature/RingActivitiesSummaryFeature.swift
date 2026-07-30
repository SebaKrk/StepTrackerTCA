//
//  RingActivitiesSummaryFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 17/10/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels
import HealthHub

@Reducer
struct RingActivitiesSummaryFeature {
    
    // MARK: - Dependency
    
    @Dependency(\.activityRingManager) var activityRingManager
    @Dependency(\.continuousClock) var clock
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
                // MARK: - Internal Action
            case let .internal(.changeViewState(value)):
                state.viewState = value
                switch value {
                case .success, .failed:
                    return .send(.delegate(.refreshDidComplete))
                case .loading:
                    return .none
                }
                
            case let .internal(.activityRingDataLoaded(data)):
                state.activityRingData = data
                return .none
                
            case .internal(.fetchTodaySummary):
                return .run { send in
                    do {
                        await send(.internal(.changeViewState(.loading)))
                        
                        var data: ActivityRingData
#if targetEnvironment(simulator)
                        data = .mock
#else
                        data = try await activityRingManager.fetchTodaySummary()
#endif
                        try await clock.sleep(for: .milliseconds(500))
                        await send(.internal(.changeViewState(.success)))
                        await send(.internal(.activityRingDataLoaded(data)))
                    } catch {
                        await send(.internal(.failedToLoadRingData))
                    }
                }
                
            case .internal(.failedToLoadRingData):
                return .send(.internal(.changeViewState(.failed)))
                
                // MARK: - View Action
                
            case .view(.viewDidAppear):
                guard state.activityRingData == nil else {
                    return .none
                }
                return .send(.internal(.fetchTodaySummary))

            case .view(.refresh):
                return .send(.internal(.fetchTodaySummary))
                
            case .view(.showDetailsButtonTapped):
                guard let data = state.activityRingData else {
                    return .none
                }
                
                state.destination = .details(RingActivitiesSummaryDetailsFeature.State(activityRingData: data))
                return .none
                
                // MARK: - Destination

            case .destination(_):
                return .none

                // MARK: - Delegate

            case .delegate(_):
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
    
}

/// Implementation of `RingActivitiesSummaryFeature` action
extension RingActivitiesSummaryFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Internal Actions
        
        case `internal`(Internal)
        
        enum Internal {
            
            /// Updates the current loading state of the view
            /// - Parameter value: The new view state (loading, success, or failed)
            case changeViewState(ViewState)
            
            /// Initiates fetching today's activity summary from HealthKit
            case fetchTodaySummary
            
            /// Stores the successfully fetched activity ring data
            /// - Parameter data: The activity ring data containing move, exercise, and stand values
            case activityRingDataLoaded(ActivityRingData)
            
            /// Handles failures during data fetching operations
            case failedToLoadRingData
            
        }
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            ///
            case showDetailsButtonTapped
            
            /// Action triggered when the view appears on the screen.
            case viewDidAppear
            
            /// Action triggered when user pulls to refresh
            case refresh
        }
        
        // MARK: - Destination

        /// Destination case for handling navigation actions.
        /// - Parameter action: The action to be performed within the destination.
        case destination(PresentationAction<Destination.Action>)

        // MARK: - Delegate Action

        case delegate(Delegate)

        enum Delegate {

            /// Signals to parent that this feature has finished its refresh cycle
            /// (entered a terminal state — `.success` or `.failed`).
            case refreshDidComplete
        }
    }
}

/// Implementation of `RingActivitiesSummaryFeature` state
extension RingActivitiesSummaryFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        /// Current loading state of the view
        /// - `loading`: Data is being fetched
        /// - `success`: Data fetched successfully
        /// - `failed`: Error occurred during fetch
        var viewState: ViewState = .loading
        
        /// The fetched activity ring data containing daily metrics
        /// - `nil` when no data has been fetched yet
        var activityRingData: ActivityRingData? = nil
        
        /// Represents the navigation destination state within `RingActivitiesSummaryFeature`.
        /// This property handles transitions to different screens or modals within the feature.
        @Presents var destination: Destination.State?
        
    }
    
}

/// Implementation of `RingActivitiesSummaryFeature` destination
extension RingActivitiesSummaryFeature {
    
    @Reducer
    enum Destination {
        
        ///
        case details(RingActivitiesSummaryDetailsFeature)
    }
    
}
