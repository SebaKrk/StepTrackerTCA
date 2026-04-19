//
//  ReadinessTrendFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 16/04/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

/// Feature displaying training readiness trend as a line chart with zone bands.
///
/// Fetches readiness history from `TrainingReadinessClient` and displays
/// it as a line chart with colored zone bands (excellent/good/fair/poor).
/// Requires Pro subscription tier.
@Reducer
struct ReadinessTrendFeature {

    // MARK: - Dependency

    @Dependency(\.trainingReadinessClient) var trainingReadinessClient

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

                // MARK: - Internal

            case .internal(.fetchData):
                state.viewState = .loading
                state.isChartAnimated = false
                let days = state.dateRange.rawValue
                return .run { [trainingReadinessClient] send in
                    await send(.internal(.dataResponse(
                        Result { try await trainingReadinessClient.history(days) }
                    )))
                }

            case let .internal(.dataResponse(.success(data))):
                state.historyData = data
                state.viewState = .success
                state.contentState = .ready(state.subscriptionTier)
                return .run { send in
                    try? await Task.sleep(for: .milliseconds(50))
                    await send(.internal(.revealChart))
                }

            case .internal(.dataResponse(.failure)):
                state.viewState = .failed
                state.contentState = .noData
                return .none

            case .internal(.revealChart):
                state.isChartAnimated = true
                return .none

                // MARK: - View

            case .view(.viewDidAppear):
                guard state.historyData == nil else {
                    return .none
                }
                return .send(.internal(.fetchData))

            case .view(.refresh):
                state.selectedDataPoint = nil
                return .send(.internal(.fetchData))

            case let .view(.dateRangeChanged(range)):
                state.dateRange = range
                state.selectedDataPoint = nil
                return .send(.internal(.fetchData))

            case let .view(.dataPointSelected(result)):
                state.selectedDataPoint = result
                return .none
            }
        }
    }
    
}
