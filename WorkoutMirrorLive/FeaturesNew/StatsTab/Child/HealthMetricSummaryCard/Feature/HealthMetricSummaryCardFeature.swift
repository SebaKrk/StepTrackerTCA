//
//  HealthMetricSummaryCardFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 11/10/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels

@Reducer
struct HealthMetricSummaryCardFeature {
    
    // MARK: - Dependency
    
    @Dependency(\.trainingReadinessClient) var trainingReadinessClient
    @Dependency(\.continuousClock) var clock
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
                // MARK: - Internal Action
            case let .internal(.changeContentState(newState)):
                state.contentState = newState
                return .none
                
            case let .internal(.dataLoaded(data)):
                state.components = data
                return .run {  [tier = state.subscriptionTier] send in
                    try await clock.sleep(for: .seconds(2))
                    await send(.internal(.changeContentState(.ready(tier))))
                }
                
            case .internal(.loadSummaryData):
                return .run { send in
                    do {
                        let result = try await trainingReadinessClient.calculate()
                        
                        if result.healthKitAccessDenied {
                            await send(.internal(.changeContentState(.unauthorized)))
                        } else {
                            await send(.internal(.dataLoaded(result.components)))
                        }
                    } catch {
                        await send(.internal(.changeContentState(.noData)))
                        print(error.localizedDescription)
                    }
                }
                
                // MARK: - View Action
                
            case .view(.viewDidAppear):
                return .send(.internal(.loadSummaryData))
                
            case .view(.refresh):
                return .send(.internal(.loadSummaryData))
                
            case let .view(.showDetailsButtonTapped(metric: metric, data: score)):
                state.destination = .details(HealthMetricSummaryDetailsCardFeature.State(metricType: metric,
                                                                                         initialData: score))
                return .none
                
                // MARK: - Destination
                
            case .destination(_):
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
    
}
