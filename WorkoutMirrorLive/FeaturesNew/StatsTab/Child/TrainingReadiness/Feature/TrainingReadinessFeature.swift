//
//  TrainingReadinessFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 26/09/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels
import HealthHub
import SwiftUI

/// A feature responsible for managing the Training Readiness state.
///
/// This feature handles:
/// - Calculating the readiness score based on HealthKit data.
/// - Managing the content state (loading, ready, noData, unauthorized).
/// - communicating with the WidgetDataClient to update homescreen widgets.
/// - Delegating refresh requests to the parent feature.
@Reducer
struct TrainingReadinessFeature {
    
    // MARK: - Dependency
    
    @Dependency(\.trainingReadinessClient) var trainingReadinessClient
    @Dependency(\.widgetDataClient) var widgetDataClient
    @Dependency(\.continuousClock) var clock
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
                
                // MARK: - Action
            case let .internal(.changeContentState(newState)):
                state.contentState = newState
                return .none
                
                
            case .internal(.changeColor):
                state.$color.withLock { $0 = state.readinessLevel.color }
                return .none
                
            case let .internal(.readinessCalculated(result)):
                state.readinessResult = result
                return .run {  [tier = state.subscriptionTier] send in
                    await widgetDataClient.saveReadinessResult(result)
                    await send(.internal(.changeColor))
                    try await clock.sleep(for: .seconds(2))
                    await send(.internal(.changeContentState(.ready(tier))))
                }
                
            case let .internal(.calculationFailed(error)):
                state.errorMessage = error
                state.$color.withLock { $0 = .gray }
                return .send(.internal(.changeContentState(.noData)))
                
            case .internal(.loadReadinessData):
                return .run { send in
                    // Simulate loading delay for skeleton visibility
                    // This ensures the skeleton animation is visible for at least 2 seconds
                    // providing a consistent UX with other cards even if calculation is instant.
                    try await clock.sleep(for: .seconds(2))
                    
                    do {
                        let result = try await trainingReadinessClient.calculate()
                        
                        if result.healthKitAccessDenied {
                            await widgetDataClient.clear()
                            await send(.internal(.changeContentState(.unauthorized)))
                        } else if result.hasInsufficientData {
                            await widgetDataClient.clear()
                            // If data is insufficient (e.g. no RHR/HRV), we enter .noData state.
                            // This triggers the overlay in the View, which offers a "Refresh" button.
                            await send(.internal(.changeContentState(.noData)))
                        } else {
                            await send(.internal(.readinessCalculated(result)))
                        }
                    } catch {
                        await send(.internal(.calculationFailed(error.localizedDescription)))
                    }
                }
                
                // MARK: - View Actions
                
            case .view(.viewDidAppear):
                guard state.readinessResult == nil,
                      state.contentState == .noData else {
                    return .none
                }
                return .concatenate(
                    .send(.internal(.changeContentState(.loading))),
                    .send(.internal(.loadReadinessData))
                )
                
            case .view(.refresh):
                return .concatenate(
                    .send(.internal(.changeContentState(.loading))),
                    .send(.internal(.loadReadinessData))
                )
                
            case .view(.retryButtonTapped):
                return .send(.delegate(.refreshRequested))
                
            case .delegate(.refreshRequested):
                return .none
            }
        }
        //._printChanges()
    }
    
}
