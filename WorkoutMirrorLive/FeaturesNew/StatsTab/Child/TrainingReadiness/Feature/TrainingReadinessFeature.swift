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
    @Dependency(\.date) var date

    // MARK: - Cancellation

    /// Identifies the in-flight calculation so a new one replaces it.
    nonisolated enum CancelID: Hashable {

        /// The readiness calculation effect.
        case load

        /// The timer that retries once the night should have closed.
        case awaitingDeadline
    }

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
                state.errorMessage = nil
                state.$color.withLock { $0 = .gray }
                // Terminal state, not a failure: the card explains the wait
                // itself, so the "no data / retry" overlay must stay away.
                return .merge(
                    .send(
                        .internal(.changeContentState(.ready(state.subscriptionTier))),
                        animation: .snappy(duration: 0.3)
                    ),
                    wakeUpEffect(at: expectedBy)
                )

            case .internal(.awaitingDeadlineReached):
                return .send(.internal(.loadReadinessData))

            case let .internal(.noScore(contentState)):
                state.readinessResult = nil
                state.availability = .available
                state.$color.withLock { $0 = .gray }
                return .send(
                    .internal(.changeContentState(contentState)),
                    animation: .snappy(duration: 0.3)
                )

            case let .internal(.calculationFailed(error)):
                state.errorMessage = error
                return .send(.internal(.noScore(.noData)))
                
            case .internal(.loadReadinessData):
                return .run { send in
                    Logger.stats.info("[TR-Refresh] loadReadinessData START")
                    // Anti-flash skeleton: keep the loading state visible for at
                    // least 500ms even when the calculation is fast. Started
                    // alongside the calculation, not before it, so it sets a
                    // floor on perceived latency instead of adding to it.
                    async let minimumVisibility: Void = clock.sleep(for: .milliseconds(500))

                    do {
                        let outcome = try await trainingReadinessClient.calculate()
                        try await minimumVisibility
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
                            await send(.internal(.noScore(.noData)))

                        case .accessDenied:
                            await widgetDataClient.clear()
                            await send(.internal(.noScore(.unauthorized)))
                        }
                    } catch is CancellationError {
                        return
                    } catch {
                        try? await minimumVisibility
                        await send(.internal(.calculationFailed(error.localizedDescription)))
                    }
                }
                .cancellable(id: CancelID.load, cancelInFlight: true)
                
                // MARK: - View Actions
                
            case .view(.viewDidAppear):
                // A morning spent waiting leaves the card in `.ready` with no
                // result, so keying on `.noData` alone would never retry once the
                // night closed. Denied access is excluded: retrying it on every
                // appearance only re-asks HealthKit for a refusal.
                guard state.contentState != .loading,
                      state.contentState != .unauthorized,
                      state.readinessResult == nil else {
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

            case .view(.infoButtonTapped):
                state.destination = .explanation(ReadinessExplanationFeature.State())
                return .none

                // MARK: - Destination Actions

            case .destination:
                return .none
                
            case .delegate(.refreshRequested),
                 .delegate(.refreshDidComplete):
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
        //._printChanges()
    }

    // MARK: - Private Methods

    /// Retries once the night should have closed.
    ///
    /// Without this the card promises a score "after 10:00" and then does
    /// nothing at 10:00 for a user who stays on the screen.
    private func wakeUpEffect(at deadline: Date?) -> Effect<Action> {
        guard let deadline else { return .none }

        let delay = deadline.timeIntervalSince(date.now)

        guard delay > 0 else { return .none }

        return .run { send in
            try await clock.sleep(for: .seconds(delay))
            await send(.internal(.awaitingDeadlineReached))
        }
        .cancellable(id: CancelID.awaitingDeadline, cancelInFlight: true)
    }

}
