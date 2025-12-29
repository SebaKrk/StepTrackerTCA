//
//  ActivityDetailsFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 26/12/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels
import SwiftUI
import HealthKit

@Reducer
struct ActivityDetailsFeature {
    
    // MARK: - Dependency
    
    @Dependency(\.activityClient) var activityClient
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
            case let .internal(.zoneExpand(value)):
                state.isExpandZone = value
                return .none
                
            case let .internal(.zoneDistributionLoaded(distribution)):
                state.zoneDistribution = distribution
                return .none
                
            case .view(.viewDidAppear):
                guard state.zoneDistribution == nil else { return .none }
                
                let workout = state.workout
                let maxHeartRate = state.maxHeartRate
                
                return .run { send in
                    let distribution = try await activityClient.fetchZoneDistribution(workout, maxHeartRate)
                    await send(.internal(.zoneDistributionLoaded(distribution)))
                } catch: { error, send in
                    print("❌ Failed to load zone distribution: \(error)")
                }
                
            case let .view(.zoneDiscusserButtonTapped(value)):
                return .send(.internal(.zoneExpand(value)))

            }
        }
    }
}

// MARK: - Action

extension ActivityDetailsFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        ///
        case `internal`(Internal)
        
        ///
        enum Internal {
            
            ///
            case zoneDistributionLoaded([HeartRateZone: TimeInterval])
            
            ///
            case zoneExpand(Bool)
        }
        
        ///
        case view(View)
        
        ///
        enum View {
            
            ///
            case viewDidAppear
            
            ///
            case zoneDiscusserButtonTapped(Bool)
        }
        
    }
}

// MARK: - State

extension ActivityDetailsFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Shared
        
        @Shared(.inMemory(.readinessLevelColor))
        var color: Color = .clear
        
        // MARK: - Properties
        
        ///
        var workout: HKWorkout
        
        ///
        var maxHeartRate: Double
        
        ///
        var primaryZoneInfo: PrimaryZoneInfo?
        
        ///
        var zoneDistribution: [HeartRateZone: TimeInterval]?
        
        ///
        var isExpandZone: Bool = false
        
        // MARK: - Init
        
        init(workout: HKWorkout, maxHeartRate: Double, primaryZoneInfo: PrimaryZoneInfo? = nil) {
            self.workout = workout
            self.maxHeartRate = maxHeartRate
            self.primaryZoneInfo = primaryZoneInfo
        }
    }
}
