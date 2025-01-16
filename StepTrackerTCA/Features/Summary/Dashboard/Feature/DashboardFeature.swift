//
//  DashboardFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 21/12/2024.
//

import ComposableArchitecture
import Factory
import Foundation

@Reducer
struct DashboardFeature {
    
    // MARK: - Properties
    
    var dashboardFeatureService: DashboardFeatureService
    
    // MARK: - Lifecycle
    
    init(service: DashboardFeatureService) {
        self.dashboardFeatureService = service
    }
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        CombineReducers {
            BindingReducer()
            Reduce { state, action in
                switch action {
                    
                    // MARK: - Binding
                case .binding(_):
                    return .run { [date = state.rawSelectedDate, value = state.rawSelectedChartValue] send  in
                        if let date = date {
                            await send(.selectedStepChartDateChange(date))
                        } else {
                            await send(.selectedStepChartDateChange(nil))
                        }
                        
                        if let value = value {
                            await send(.rawSelectedChartValueChange(value))
                        } else {
                            await send(.rawSelectedChartValueChange(nil))
                        }
                    }
                    
                    // MARK: - Actions
                case let .selectedStepChartDateChange(date):
                    if date == nil {
                        state.selectedHealthMetric = nil
                    } else {
                        state.selectedHealthMetric = dashboardFeatureService.selectedHealthMetric(from: state.stepData,
                                                                                                  with: date)
                    }
                    return .none
                    
                case let .rawSelectedChartValueChange(value):
                    if value == nil {
                        state.selectedChartValue = nil
                    } else {
                        state.selectedChartValue = dashboardFeatureService.selectedWeekday(from: state.stepDataPerWeekDay,
                                                                                           with: value)
                    }
                    return .none
                    
                case let .selectedPickerChange(item):
                    state.healthMetric = item
                    return .none
                    
                case .changeIsFirstAppearance:
                    state.hasSeenPermissionPriming = dashboardFeatureService.hasSeenPermissionPriming
                    return .none
                    
                case .fetchHealthData:
                    return .run { send in
                        await send(.updateStepChartData(
                            Result {
                                try await dashboardFeatureService.getStepsData()
                            }
                        ))
                        
                        await send(.updateWeightChartData(
                            Result {
                                try await dashboardFeatureService.getWeightData()
                            }
                        ))
                        
                    }
                    
                case let .updateStepChartData(.success(data)):
                    state.stepData = data
                    state.avgStepCount = dashboardFeatureService.calculateAverageStepCount(from: data)
                    state.stepDataPerWeekDay = dashboardFeatureService.calculateAverageHealthDataPerWeekday(state.stepData)
                    state.selectedChartValue = state.stepDataPerWeekDay.first
                    state.totalStepsFrom28Days = dashboardFeatureService.calculateTotalSteps(from: data)
                    return .none
                    
                    // TODO: Error handling
                    /// Add failure handling to the fetchHealthData
                case let .updateStepChartData(.failure(error)):
                    print(error.localizedDescription)
                    return .none
                    
                case let .updateWeightChartData(.success(data)):
                    state.weightData = data
//                    state.weightMinValue = dashboardFeatureService.calculateMinValue(from: data)
//                    state.averageWeight = dashboardFeatureService.calculateWeightAverage(from: data)
                    return .none
                    
                case let .updateWeightChartData(.failure(error)):
                    print(error.localizedDescription)
                    return .none
                    
                    // MARK: - View actions
                case .view(.viewDidAppear):
                    if !dashboardFeatureService.hasSeenPermissionPriming {
                        return .run { send in
                            await send(.openPermissionScreen)
                        }
                    } else {
                        return .run { send in
                            /// use only first time
                            //try await dashboardFeatureService.getDummyData()
                            await send(.fetchHealthData)
                        }
                    }
                    
                    // MARK: - Destination
                case .openPermissionScreen:
                    dashboardFeatureService.markPermissionPrimingAsSeen()
                    state.destination = .openHealthKitPermissionScreen(HealthKitPermissionFeature.State())
                    return .none
                    
                    // MARK: - Path
                case let .path(action):
                    switch action {
                    case .element(id: _, action: .healthDataListFeature(.navigateToHealthDataList)):
                        state.path.append(.healthDataListFeature(HealthDataListFeature.State(healthMetric: state.healthMetric)))
                        return .none
                        
                    default: return .none
                    }
                    
                default: return .none
                }
            }
        }
        .forEach(\.path, action: \.path)
        .ifLet(\.$destination, action: \.destination)
        
        Scope(state: \.weightGoalWidget, action: \.weightGoalWidget) {
            WeightGoalWidgetFeature(service: DefaultWeightGoalWidgetService())
        }
    }
    
}
