//
//  StepWidgetFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 16/01/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct StepWidgetFeature {
    
    // MARK: - Properties
    
    var stepWidgetService: StepWidgetService
    
    // MARK: - Lifecycle
    
    init(service: StepWidgetService) {
        self.stepWidgetService = service
    }
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        CombineReducers {
            BindingReducer()
            Reduce { state, action in
                switch action {
                    // MARK: - Binding
                case .binding(_):
                    return .run { [date = state.rawSelectedDate]  send  in
                        if let date = date {
                            await send(.selectedStepChartDateChange(date))
                        } else {
                            await send(.selectedStepChartDateChange(nil))
                        }
                    }
                    
                    // MARK: - Actions
                case let .selectedStepChartDateChange(date):
                    if date == nil {
                        state.selectedHealthMetric = nil
                    } else {
                        state.selectedHealthMetric = stepWidgetService.selectedHealthMetric(from: state.stepData, with: date)
                    }
                    return .none
                    
                case let .updateStepChartData(stepData):
                    state.stepData = stepData
                    state.avgStepCount = stepWidgetService.calculateAverageStepCount(from: stepData)
                    return .none
                    
                case .refresh:
                    return .run { [stepData = state.stepData] send in
                        await send(.updateStepChartData(stepData))
                    }
                    
                    // MARK: - View Actions
                case .view(.tapDestination):
                    return .send(.show)
                    
                case .view(.viewDidAppear):
                    return .none
                    
                    // MARK: - Destination
                case .show:
                    state.destination = .detailList(HealthDataListFeature.State(healthData: state.stepData, healthMetric: .steps))
                    return .none
                    
                case .destination:
                    return .none
                }
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
    
}
