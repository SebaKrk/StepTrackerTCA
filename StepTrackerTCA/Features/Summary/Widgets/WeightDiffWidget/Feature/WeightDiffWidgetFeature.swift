//
//  WeightDiffWidgetFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 17/01/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct WeightDiffWidgetFeature {
    
    // MARK: - Properties
    
    var weightDiffWidgetService: WeightDiffService
    
    // MARK: - Lifecycle
    
    init(service: DefaultWeightDiffService) {
        self.weightDiffWidgetService = service
    }
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        CombineReducers {
            BindingReducer()
            Reduce { state, action in
                switch action {
                    
                    // MARK: - Binding
                case .binding(_):
                    return .run { [date = state.rawSelectedDate] send  in
                        if let date = date {
                            await send(.selectedChartDateChange(date))
                        } else {
                            await send(.selectedChartDateChange(nil))
                        }
                    }
                    
                    // MARK: - Actions
                case let .selectedChartDateChange(date):
                    if date == nil {
                        state.selectedHealthMetric = nil
                    } else {
                        state.selectedHealthMetric = weightDiffWidgetService.selectedHealthMetric(from: state.weightDataPerWeekDay, with: date)
                    }
                    return .none
                    
                case let .updateWeightChartData(weightData):
                    state.weightData = weightData
                    state.weightDataPerWeekDay = weightDiffWidgetService.averageDailyWeightDiffs(for: weightData)
                    return .none
                    
                case .refresh:
                    return .run { [weightData = state.weightData] send in
                        await send(.updateWeightChartData(weightData))
                    }
                    
                    // MARK: - View Actions
                case .view(.viewDidAppear):
                    return .none
                }
            }
        }
    }
    
}
