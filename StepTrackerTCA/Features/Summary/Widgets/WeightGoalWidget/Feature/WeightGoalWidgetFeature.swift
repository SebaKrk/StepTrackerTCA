//
//  WeightGoalWidgetFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 16/01/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct WeightGoalWidgetFeature {
    
    // MARK: - Properties
    
    var weightGoalWidgetService: WeightGoalWidgetService
    
    // MARK: - Lifecycle
    
    init(service: WeightGoalWidgetService) {
        self.weightGoalWidgetService = service
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
                        state.selectedHealthMetric = weightGoalWidgetService.selectedHealthMetric(from: state.weightData, with: date)
                    }
                    return .none
                    
                case let .updateWeightChartData(weightData):
                    state.weightData = weightData
                    state.weightMinValue = weightGoalWidgetService.calculateMinValue(from: weightData)
                    state.averageWeight = weightGoalWidgetService.calculateWeightAverage(from: weightData)
                    return .none
                    
                case .refresh:
                    return .run { [weightData = state.weightData] send in
                        await send(.updateWeightChartData(weightData))
                    }
                    
                    // MARK: - View Actions
                case .view(.tapDestination):
                    return .send(.show)
                    
                case .view(.viewDidAppear):
                    return .none
                    
                    // MARK: - Destination
                case .show:
                    state.destination = .detailList(HealthDataListFeature.State(healthData: state.weightData, healthMetric: .weight))
                    return .none
                    
                case .destination:
                    return .none
                }
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
    
}
