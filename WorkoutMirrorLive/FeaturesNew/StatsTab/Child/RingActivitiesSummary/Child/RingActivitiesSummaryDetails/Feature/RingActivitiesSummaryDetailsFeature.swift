//
//  RingActivitiesSummaryDetailsFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 19/10/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels
import HealthHub
import SwiftUI

@Reducer
struct RingActivitiesSummaryDetailsFeature {
    
    // MARK: - Dependency
    
    @Dependency(\.activityRingManager) var activityRingManager
    @Dependency(\.continuousClock) var clock
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        CombineReducers {
            BindingReducer()
            Reduce { state, action in
                switch action {
                    
                    // MARK: - Binding
                    
                case .binding(_):
                    return .none
                    
                    // MARK: - Internal Action
                    
                case let .internal(.changeViewState(value)):
                    state.viewState = value
                    return .none
                    
                case let .internal(.hourlyActivityDataLoaded(data)):
                    state.hourlyData = data
                    return .none
                    
                case .internal(.fetchHourlyActivityData):
                    return .run { send in
                        do {
                            await send(.internal(.changeViewState(.loading)))
                            let data = try await activityRingManager.fetchTodayHourlyData()
                            try await clock.sleep(for: .seconds(2))
                            await send(.internal(.changeViewState(.success)))
                            await send(.internal(.hourlyActivityDataLoaded(data)))
                        } catch {
                            print("❌ Error fetching hourly activity data: \(error.localizedDescription)")
                            await send(.internal(.changeViewState(.failed)))
                        }
                    }
                    
                    // MARK: - View Action
                    
                case .view(.viewDidAppear):
                    return .send(.internal(.fetchHourlyActivityData))
                }
            }
        }
    }
    
}

// MARK: - Action

/// Implementation of `RingActivitiesSummaryDetailsFeature` action
extension RingActivitiesSummaryDetailsFeature {
    
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - Internal Actions
        
        /// Internal actions for state management and data fetching
        case `internal`(Internal)
        
        enum Internal {
            
            /// Updates the current loading state of the view
            /// - Parameter value: The new view state (loading, success, or failed)
            case changeViewState(ViewState)
            
            /// Initiates the fetch operation for today's hourly activity data
            case fetchHourlyActivityData
            
            /// Handles the successful loading of hourly activity data
            /// - Parameter data: Array of hourly activity data points
            case hourlyActivityDataLoaded([HourlyActivityData])
        }
        
        // MARK: - View Actions
        
        /// Actions triggered directly from the view
        case view(View)
        
        enum View {
            
            /// Action triggered when the view appears on the screen.
            /// Initiates data fetching on view appearance.
            case viewDidAppear
        }
    }
}

// MARK: - State

/// Implementation of `RingActivitiesSummaryDetailsFeature` state
extension RingActivitiesSummaryDetailsFeature {
    
    @ObservableState
    struct State {
        
        /// Shared color state used for gradient backgrounds based on readiness level
        @Shared(.inMemory(.readinessLevelColor))
        var color: Color = .gray
        
        // MARK: - Properties
        
        /// Current loading state of the view
        /// Used to show skeleton loading states and manage UI feedback
        var viewState: ViewState = .loading
  
        /// The activity ring data containing daily metrics (move, exercise, stand totals)
        var activityRingData: ActivityRingData
        
        /// Array of hourly activity data for the current day
        /// Contains breakdown of move, exercise, and stand activities for each hour
        var hourlyData: [HourlyActivityData] = []

        /// Currently selected hour (0-23) in the activity charts
        /// When set, displays detailed metrics for that specific hour
        var selectedHour: Int?
    }
    
}
