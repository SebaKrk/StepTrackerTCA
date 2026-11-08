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
                switch newState {
                case .ready, .noData, .unauthorized:
                    return .send(.delegate(.refreshDidComplete))
                case .loading:
                    return .none
                }
                
            case let .internal(.dataLoaded(data)):
                state.components = data
                return .run {  [tier = state.subscriptionTier] send in
                    try await clock.sleep(for: .milliseconds(500))
                    await send(.internal(.changeContentState(.ready(tier))))
                }
                
            case .internal(.loadSummaryData):
                return .run { send in
                    do {
                        let outcome = try await trainingReadinessClient.calculate()

                        switch outcome {
                        case let .ready(result):
                            await send(.internal(.dataLoaded(result.components)))

                        case .accessDenied:
                            await send(.internal(.changeContentState(.unauthorized)))

                        case .awaitingSleepData, .insufficientData:
                            // Placeholders rather than an error: these metrics
                            // simply have nothing to show for the day yet.
                            await send(.internal(.dataLoaded(nil)))
                        }
                    } catch {
                        // Instead of showing global error, we load nil data to trigger placeholders
                        await send(.internal(.dataLoaded(nil)))
                        print("TrainingReadiness Error (Handled as Empty): \(error.localizedDescription)")
                    }
                }
                
                // MARK: - View Action
                
            case .view(.viewDidAppear):
                guard state.components == nil else { return .none }
                return .concatenate(
                    .send(.internal(.changeContentState(.loading))),
                    .send(.internal(.loadSummaryData))
                )
                
            case .view(.refresh):
                return .concatenate(
                    .send(.internal(.changeContentState(.loading))),
                    .send(.internal(.loadSummaryData))
                )
                
            case let .view(.showDetailsButtonTapped(metric: metric, data: score)):
                state.destination = .details(HealthMetricSummaryDetailsCardFeature.State(metricType: metric,
                                                                                         initialData: score))
                return .none
                
                // MARK: - Destination

            case .destination(_):
                return .none

                // MARK: - Delegate

            case .delegate(_):
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
    
}
