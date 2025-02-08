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
                    return .none
                    
                    // MARK: - Actions
                case .changeIsFirstAppearance:
                    state.isFirstAppearance = false
                    state.hasSeenPermissionPriming = dashboardFeatureService.hasSeenPermissionPriming
                    return .none
                    
                case let .changeViewState(viewState):
                    state.viewState = viewState
                    return .none
                    
                case let .selectedPickerChange(item):
                    state.healthMetric = item
                    return .none
                    
                case .fetchHealthData:
                    return .run { send in
                        await send(.updateStepChartData(
                            Result { try await dashboardFeatureService.getStepsData()}))
                        await send(.updateWeightChartData(
                            Result { try await dashboardFeatureService.getWeightData() }))
                    }
                    
                case let .updateStepChartData(.success(data)):
                    state.stepData = data
                    return .run { send in
                        if data.isEmpty {
                            await send(.changeViewState(.noContentAvailable))
                            return
                        }
                        await send(.changeViewState(.successfullyLoaded))
                        await send(.changeIsFirstAppearance)
                        await send(.stepPieWidget(.updatePieChartData(data)))
                        await send(.stepWidget(.updateStepChartData(data)))
                    }
                    
                case let .updateStepChartData(.failure(error)):
                    print("❌ Failed to fetch step data: \(error.localizedDescription)")
                    return .none
                    
                case let .updateWeightChartData(.success(data)):
                    state.weightData = data
                    
                    return .run { send in
                        if data.isEmpty {
                            await send(.changeViewState(.noContentAvailable))
                            return
                        }
                        await send(.changeViewState(.successfullyLoaded))
                        await send(.changeIsFirstAppearance)
                        await send(.weightDiffWidget(.updateWeightChartData(data)))
                        await send(.weightGoalWidget(.updateWeightChartData(data)))
                    }
                    
                case let .updateWeightChartData(.failure(error)):
                    print("❌ Failed to fetch weigh data: \(error.localizedDescription)")
                    return .none
                    
                case .getDummyData:
                    return .run {  [stepData = state.stepData, weightData = state.weightData] send in
                        if stepData.isEmpty && weightData.isEmpty {
                            try await dashboardFeatureService.getDummyData()
                            await send(.updateDummyData)
                        } else {
                            print("Health data already exists.")
                        }
                    }
                    
                case .updateDummyData:
                    return .run { send in
                        await send(.fetchHealthData)
                    }
                    
                    // MARK: - View actions
                case .view(.mockDataButtonTapped):
                    return .run { send in
                        await send(.changeViewState(.loading))
                        await send(.getDummyData)
                    }
                    
                case .view(.viewDidAppear):
                    if !dashboardFeatureService.hasSeenPermissionPriming {
                        return .run { send in
                            await send(.changeViewState(.loading))
                            await send(.openPermissionScreen)
                        }
                    } else {
                        return .run { [state] send in
                            if state.isFirstAppearance {
                                await send(.fetchHealthData)
                            }
                        }
                    }
                    
                case .view(.userPulledToRefresh):
                    return .run { send in
                        await send(.fetchHealthData)
                        await send(.stepPieWidget(.refresh))
                        await send(.stepWidget(.refresh))
                        await send(.weightDiffWidget(.refresh))
                        await send(.weightGoalWidget(.refresh))
                    }
                    
                    // MARK: - Destination
                case .openPermissionScreen:
                    dashboardFeatureService.markPermissionPrimingAsSeen()
                    state.destination = .openHealthKitPermissionScreen(HealthKitPermissionFeature.State())
                    return .none
                    
                case .destination(.presented(.openHealthKitPermissionScreen(.delegate(.success)))):
                    return .run {  send in
#if targetEnvironment(simulator)
                        print("📱 Running on SIMULATOR")
                        await send(.changeViewState(.noContentAvailable))
#else
                        print("📱 Running on PHYSICAL DEVICE")
                        await send(.fetchHealthData)
#endif
                    }
                    
                default: return .none
                }
            }
        }
        .ifLet(\.$destination, action: \.destination)
        
        Scope(state: \.stepPieWidget, action: \.stepPieWidget) {
            StepPieWidgetFeature(service: DefaultStepPieWidget())
        }
        
        Scope(state: \.stepWidget, action: \.stepWidget) {
            StepWidgetFeature(service: DefaultStepWidgetService())
        }
        
        Scope(state: \.weightDiffWidget, action: \.weightDiffWidget) {
            WeightDiffWidgetFeature(service: DefaultWeightDiffService())
        }
        
        Scope(state: \.weightGoalWidget, action: \.weightGoalWidget) {
            WeightGoalWidgetFeature(service: DefaultWeightGoalWidgetService())
        }
    }
    
}
