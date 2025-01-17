//
//  StepPieWidgetFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 16/01/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct StepPieWidgetFeature {
    
    // MARK: - Properties
    
    var stepPieWidgetService: StepPieWidgetService
    
    // MARK: - Lifecycle
    
    init(service: StepPieWidgetService) {
        self.stepPieWidgetService = service
    }
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        CombineReducers {
            BindingReducer()
            Reduce { state, action in
                switch action {
                    
                    // MARK: - Binding
                case .binding(_):
                    return .run { [value = state.rawSelectedChartValue] send  in
                        if let value = value {
                            await send(.rawSelectedChartValueChange(value))
                        } else {
                            await send(.rawSelectedChartValueChange(nil))
                        }
                    }
                    
                    // MARK: - Actions
                case let .updatePieChartData(stepData):
                    state.stepData = stepData
                    state.stepDataPerWeekDay = stepPieWidgetService.calculateAverageHealthDataPerWeekday(stepData)
                    state.selectedChartValue = state.stepDataPerWeekDay.first
                    state.totalStepsFrom28Days = stepPieWidgetService.calculateTotalSteps(from: stepData)
                    return .none
                    
                case let .rawSelectedChartValueChange(value):
                    if value == nil {
                        state.selectedChartValue = nil
                    } else {
                        state.selectedChartValue = stepPieWidgetService.selectedWeekday(from: state.stepDataPerWeekDay, with: value)
                    }
                    return .none
                    
                    // MARK: - View Actions
                case .view(.viewDidAppear):
                    print("2 StepPieWidgetFeature")
                    return .run { [stepData = state.stepData] send in
                        await send(.updatePieChartData(stepData))
                    }
                }
            }
        }
    }
    
}
