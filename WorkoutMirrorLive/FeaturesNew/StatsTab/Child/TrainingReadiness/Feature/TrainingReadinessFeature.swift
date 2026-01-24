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
                    // Save for widget
                    let widgetData = WidgetReadinessData(
                        overallScore: result.overallScore,
                        readinessLevelRaw: result.readinessLevel.title,
                        rhrValue: result.components.restingHeartRate?.currentValue,
                        hrvValue: result.components.heartRateVariability?.currentValue,
                        sleepValue: result.components.sleepQuality?.currentValue,
                        activityValue: result.components.previousDayLoad?.currentValue,
                        calculatedAt: result.calculatedAt
                    )
                    
                    await widgetDataClient.save(widgetData)
                    
                    await send(.internal(.changeColor))
                    try await clock.sleep(for: .seconds(2))
                    await send(.internal(.changeContentState(.ready(tier))))
                }
                
            case let .internal(.calculationFailed(error)):
                state.errorMessage = error
                return .send(.internal(.changeContentState(.noData)))
                
            case .internal(.loadReadinessData):
                return .run { send in
                    do {
                        let result = try await trainingReadinessClient.calculate()
                        
                        if result.healthKitAccessDenied {
                            await send(.internal(.changeContentState(.unauthorized)))
                        } else if result.hasInsufficientData {
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
                return .send(.internal(.loadReadinessData))
            }
        }
        //._printChanges()
    }
    
}
