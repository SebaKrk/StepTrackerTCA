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
                
                // MARK: - Internal State Updates
                
            case let .internal(.zoneDistributionLoaded(distribution)):
                state.zoneDistribution = distribution
                return .none
                
            case let .internal(.metricsLoaded(mets, trimp, hrTSS, hrRecovery, intensityFactor, recoveryDemand)):
                state.mets = mets
                state.trimp = trimp
                state.hrTSS = hrTSS
                state.hrRecovery = hrRecovery
                state.intensityFactor = intensityFactor
                state.recoveryDemand = recoveryDemand
                return .none
                
            case let .internal(.zoneExpand(value)):
                state.isExpandZone = value
                return .none
                
                // MARK: - Internal Data Loading
                
            case .internal(.loadZoneDistribution):
                let workout = state.workout
                let maxHeartRate = state.maxHeartRate
                
                return .run { send in
                    let distribution = try await activityClient.fetchZoneDistribution(workout, maxHeartRate)
                    await send(.internal(.zoneDistributionLoaded(distribution)))
                } catch: { error, send in
                    print("❌ Failed to load zone distribution: \(error)")
                }
                
            case .internal(.loadMetrics):
                let workout = state.workout
                let maxHeartRate = state.maxHeartRate
                
                return .run { send in
                    async let metsTask = activityClient.fetchMETs(workout)
                    async let trimpTask = activityClient.fetchTRIMP(workout, maxHeartRate)
                    async let hrTSSTask = activityClient.fetchHRTSS(workout, maxHeartRate)
                    async let hrRecoveryTask = activityClient.fetchHRRecovery(workout)
                    async let intensityFactorTask = activityClient.fetchIntensityFactor(workout, maxHeartRate)
                    async let recoveryDemandTask = activityClient.fetchRecoveryDemand(workout, maxHeartRate)
                    
                    let mets = try? await metsTask
                    let trimp = try? await trimpTask
                    let hrTSS = try? await hrTSSTask
                    let hrRecovery = try? await hrRecoveryTask
                    let intensityFactor = try? await intensityFactorTask
                    let recoveryDemand = try? await recoveryDemandTask
                    
                    await send(.internal(.metricsLoaded(
                        mets: mets,
                        trimp: trimp,
                        hrTSS: hrTSS,
                        hrRecovery: hrRecovery,
                        intensityFactor: intensityFactor,
                        recoveryDemand: recoveryDemand
                    )))
                }
                
                // MARK: - View Actions
                
            case .view(.viewDidAppear):
                guard state.zoneDistribution == nil else { return .none }
                return .merge(
                    .send(.internal(.loadZoneDistribution)),
                    .send(.internal(.loadMetrics))
                )
                
            case let .view(.zoneDiscusserButtonTapped(value)):
                return .send(.internal(.zoneExpand(value)))
                
            case let .view(.openMetricDetails(metric)):
                state.destination = .metricDetail(MetricDetailFeature.State(metricType: metric))
                return .none
                
                // MARK: - Destination
                
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

