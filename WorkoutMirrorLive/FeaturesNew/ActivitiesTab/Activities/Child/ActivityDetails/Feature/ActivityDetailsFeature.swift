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
                
            case let .internal(.zoneDistributionLoaded(distribution)):
                state.zoneDistribution = distribution
                return .none
            }
        }
    }
}

// MARK: - Action

extension ActivityDetailsFeature {
    
    @CasePathable
    enum Action: ViewAction {
        case view(View)
        case `internal`(Internal)
        
        enum View {
            case viewDidAppear
        }
        
        enum Internal {
            case zoneDistributionLoaded([HeartRateZone: TimeInterval])
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
        
        var workout: HKWorkout
        var maxHeartRate: Double
        var zoneDistribution: [HeartRateZone: TimeInterval]?
        
        // MARK: - Init
        
        init(workout: HKWorkout, maxHeartRate: Double) {
            self.workout = workout
            self.maxHeartRate = maxHeartRate
        }
    }
}
