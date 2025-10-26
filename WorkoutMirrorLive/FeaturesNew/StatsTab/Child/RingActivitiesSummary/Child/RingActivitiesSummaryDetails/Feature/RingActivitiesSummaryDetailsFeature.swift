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

@Reducer
struct RingActivitiesSummaryDetailsFeature {
    
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
                return .none
                
            case let .internal(.hourlyActivityDataLoaded(data)):
                print("💾 [STORE] Saving \(data.count) hours to state")
                state.hourlyData = data
                print("💾 [STORE] State now has \(state.hourlyData.count) hours")
                
                // ✅ DODAJ dump TUTAJ - po załadowaniu
                print("📊 [DEBUG] Dumping loaded data:")
                dump(state.hourlyData)
                
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
                        print(error.localizedDescription)
                    }
                }
                
                // MARK: - View Action
                
            case .view(.viewDidAppear):
                return .send(.internal(.fetchHourlyActivityData))
            }
        }
    }
    
}

/// Implementation of `RingActivitiesSummaryDetailsFeature` action
extension RingActivitiesSummaryDetailsFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Internal Actions
        
        case `internal`(Internal)
        
        enum Internal {
            
            /// Updates the current loading state of the view
            /// - Parameter value: The new view state (loading, success, or failed)
            case changeViewState(ViewState)
            
            ///
            case fetchHourlyActivityData
            
            ///
            case hourlyActivityDataLoaded([HourlyActivityData])

        }
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            /// Action triggered when the view appears on the screen.
            case viewDidAppear
        }
    }
}

/// Implementation of `RingActivitiesSummaryDetailsFeature` state
extension RingActivitiesSummaryDetailsFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        /// Current loading state of the view
        var viewState: ViewState = .loading
  
        /// The activity ring data containing daily metrics
        var activityRingData: ActivityRingData
        
        ///
        var hourlyData: [HourlyActivityData] = []

    }
    
}
