//
//  WeightTrendFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 16/04/2026.
//

import ComposableArchitecture
import Foundation
import HealthHub
import HealthKit
import SharedModels

/// Feature displaying a weight trend line chart over time.
///
/// Fetches daily weight data from HealthKit using `HealthKitQueryBuilder`
/// and displays it as a line chart with dots at each weigh-in.
/// Available to all subscription tiers (Basic/free).
@Reducer
struct WeightTrendFeature {

    // MARK: - Dependency

    @Dependency(\.healthStore) var healthStore

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

                // MARK: - Internal

            case .internal(.fetchData):
                state.viewState = .loading
                state.isChartAnimated = false
                let days = state.dateRange.rawValue
                return .run { [healthStore] send in
                    await send(.internal(.dataResponse(
                        Result { try await Self.fetchWeightHistory(days: days, healthStore: healthStore) }
                    )))
                }

            case let .internal(.dataResponse(.success(data))):
                state.weightData = data
                state.viewState = .success
                return .run { send in
                    try? await Task.sleep(for: .milliseconds(50))
                    await send(.internal(.revealChart))
                }

            case .internal(.dataResponse(.failure)):
                state.viewState = .failed
                return .none

            case .internal(.revealChart):
                state.isChartAnimated = true
                return .none

                // MARK: - View

            case .view(.viewDidAppear):
                guard state.weightData == nil else {
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

            case let .view(.dataPointSelected(point)):
                state.selectedDataPoint = point
                return .none
            }
        }
    }

    // MARK: - HealthKit Fetch

    static func fetchWeightHistory(days: Int, healthStore: HKHealthStore) async throws -> [WeightDataPoint] {
        guard let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) else {
            return []
        }
        let query = HealthKitQueryBuilder.buildQuery(
            for: .bodyMass,
            startDate: startDate,
            endDate: Date(),
            options: .discreteAverage
        )

        let results = try await query.result(for: healthStore)
        let healthData = HealthKitQueryBuilder.processHealthKitData(
            results.statistics(),
            unit: .gramUnit(with: .kilo),
            options: .discreteAverage
        )

        return healthData
            .filter { $0.value > 0 }
            .map { WeightDataPoint(date: $0.date, weight: $0.value) }
    }
}

