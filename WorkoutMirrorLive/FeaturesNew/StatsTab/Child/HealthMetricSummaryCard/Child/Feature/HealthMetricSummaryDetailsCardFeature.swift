//
//  HealthMetricSummaryDetailsCardFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 17/10/2025.
//

import ComposableArchitecture
import Foundation
import HealthHub
import SharedModels

/// A TCA feature that manages the detailed view of a specific health metric's historical data.
@Reducer
public struct HealthMetricSummaryDetailsCardFeature {
    
    // MARK: - Dependencies
    
    @Dependency(\.healthMetricHistoryClient) var healthMetricHistoryClient
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        CombineReducers {
            BindingReducer()
            Reduce { state, action in
                switch action {
                    
                    // MARK: - Binding
                    
                case .binding(_):
                    return .run { [date = state.rawSelectedDate] send  in
                        if let date = date {
                            await send(.internal(.selectedChartDateChange(date)))
                        } else {
                            await send(.internal(.selectedChartDateChange(nil)))
                        }
                    }
                    
                    // MARK: - Internal Actions
                    
                case let .internal(.changeViewState(value)):
                    state.viewState = value
                    return .none
                    
                case let .internal(.selectedChartDateChange(date)):
                    if date == nil {
                        state.selectedDataPoint = nil
                    } else {
                        state.selectedDataPoint = Self.selectedDataPoint(
                            from: state.historicalValues,
                            matching: date
                        )
                    }
                    return .none
                    
                case .internal(.loadHistoricalData):
                    return .run { [metricType = state.metricType] send in
                        do {
                            let dataPoints = try await healthMetricHistoryClient.fetchHistory(metricType, 7)
                            await send(.internal(.historicalDataLoaded(dataPoints)))
                        } catch {
                            await send(.internal(.loadingFailed(error)))
                        }
                    }
                    
                case let .internal(.historicalDataLoaded(dataPoints)):
                    state.historicalValues = dataPoints
                    return .run { send in
                        await send(.internal(.changeViewState(.success)))
                    }
                    
                case let .internal(.loadingFailed(error)):
                    print("❌ Failed to load historical data: \(error)")
                    return .run { send in
                        await send(.internal(.changeViewState(.failed)))
                    }
                    
                    // MARK: - View Actions
                    
                case .view(.viewDidAppear):
                    return .send(.internal(.loadHistoricalData))

                }
            }
        }
    }
    
    /// Znajduje punkt danych historycznych dla wybranej daty
    static func selectedDataPoint(
        from historicalValues: [HistoricalDataPoint],
        matching date: Date?
    ) -> HistoricalDataPoint? {
        guard let date = date else { return nil }
        return historicalValues.first {
            Calendar.current.isDate(date, inSameDayAs: $0.date)
        }
    }
    
}
