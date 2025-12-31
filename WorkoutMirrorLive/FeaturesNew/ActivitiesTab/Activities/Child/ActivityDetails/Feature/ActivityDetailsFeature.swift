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
    
    @Dependency(\.personalDataClient) var personalDataClient
    
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
                
            case let .internal(.metricsLoaded(mets)):
                state.mets = mets
                return .none
                
            case .view(.viewDidAppear):
                guard state.zoneDistribution == nil else { return .none }
                
                let workout = state.workout
                let maxHeartRate = state.maxHeartRate
                
                return .run { send in
                    
                    async let distributionTask = activityClient.fetchZoneDistribution(workout, maxHeartRate)
                    
                    async let metsTask: Double? = {
                        guard let weightData = try? await personalDataClient.getWeightForDate(workout.startDate),
                              weightData.value > 0
                        else { return nil }
                        return try? await activityClient.fetchMETs(workout, weightData.value)
                    }()
                    
                    if let distribution = try? await distributionTask {
                        await send(.internal(.zoneDistributionLoaded(distribution)))
                    }
                    
                    let mets = await metsTask
                    await send(.internal(.metricsLoaded(mets: mets)))
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
            
            case metricsLoaded(mets: Double?)

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
        
        var mets: Double?
        
        var userWeight: Double?
        
        // MARK: - Init
        
        init(workout: HKWorkout, maxHeartRate: Double, primaryZoneInfo: PrimaryZoneInfo? = nil) {
            self.workout = workout
            self.maxHeartRate = maxHeartRate
            self.primaryZoneInfo = primaryZoneInfo
        }
    }
}
