//
//  TrainingReadinessFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 26/09/2025.
//

import ComposableArchitecture
import Foundation
import OSLog
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
    @Dependency(\.watchConnectivityManager) var watchConnectivityManager
    @Dependency(\.continuousClock) var clock
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
                
                // MARK: - Action
            case let .internal(.changeContentState(newState)):
                state.contentState = newState
                switch newState {
                case .ready, .noData, .unauthorized:
                    return .send(.delegate(.refreshDidComplete))
                case .loading:
                    return .none
                }
                
                
            case .internal(.changeColor):
                state.$color.withLock { $0 = state.readinessLevel.color }
                return .none
                
            case let .internal(.readinessCalculated(result)):
                state.readinessResult = result
                state.availability = .available
                return .run {  [tier = state.subscriptionTier] send in
                    Logger.stats.info("[TR-Refresh] readinessCalculated START (saving + color change)")
                    await widgetDataClient.saveReadinessResult(result)
                    // The observer path is debounced by 5 minutes; pushing here keeps
                    // the Watch in step when the user refreshes on iPhone.
                    do {
                        try await watchConnectivityManager.publishReadinessSnapshot(
                            ReadinessSnapshot(result: result)
                        )
                    } catch {
                        Logger.stats.error("[TR-Refresh] Watch push failed: \(error.localizedDescription)")
                    }
                    await send(.internal(.changeColor))
                    await send(.internal(.changeContentState(.ready(tier))))
                }
                
            case let .internal(.awaitingSleepData(expectedBy)):
                state.availability = .awaitingSleepData(expectedBy: expectedBy)
                state.readinessResult = nil
                state.$color.withLock { $0 = .gray }
                // Terminal state, not a failure: the card explains the wait
                // itself, so the "no data / retry" overlay must stay away.
                return .send(.internal(.changeContentState(.ready(state.subscriptionTier))))

            case let .internal(.calculationFailed(error)):
                state.errorMessage = error
                state.availability = .available
                state.$color.withLock { $0 = .gray }
                return .send(.internal(.changeContentState(.noData)))
                
            case .internal(.loadReadinessData):
                return .run { send in
                    Logger.stats.info("[TR-Refresh] loadReadinessData START")
                    // Anti-flash skeleton: ensure loading state is visible for at least 500ms
                    // (industry-standard minimum visibility duration) even if HK calculation
                    // is fast. Without this, skeleton may flash and disappear before the user
                    // perceives any loading state.
                    try await clock.sleep(for: .milliseconds(500))
                    Logger.stats.info("[TR-Refresh] anti-flash sleep DONE (500ms), starting HK calc")

                    do {
                        let outcome = try await trainingReadinessClient.calculate()
                        Logger.stats.info("[TR-Refresh] HK calc DONE, dispatching outcome")

                        switch outcome {
                        case let .ready(result):
                            await send(.internal(.readinessCalculated(result)))

                        case let .awaitingSleepData(expectedBy):
                            // Not an error: the night simply has not ended yet.
                            // The widget keeps whatever it last showed.
                            await send(.internal(.awaitingSleepData(expectedBy: expectedBy)))

                        case .insufficientData:
                            await widgetDataClient.clear()
                            // Too few components to score. This triggers the overlay
                            // in the View, which offers a "Refresh" button.
                            await send(.internal(.changeContentState(.noData)))

                        case .accessDenied:
                            await widgetDataClient.clear()
                            await send(.internal(.changeContentState(.unauthorized)))
                        }
                    } catch {
                        await send(.internal(.calculationFailed(error.localizedDescription)))
                    }
                }
                
                // MARK: - View Actions
                
            case .view(.viewDidAppear):
                // Keyed on the absence of a result, not on `.noData`: a morning
                // spent waiting for sleep data leaves the card in `.ready`, and
                // the old guard would then never retry once the night closed.
                guard state.readinessResult == nil else {
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
                
            case .delegate(.refreshRequested),
                 .delegate(.refreshDidComplete):
                return .none
            }
        }
        //._printChanges()
    }
    
}
