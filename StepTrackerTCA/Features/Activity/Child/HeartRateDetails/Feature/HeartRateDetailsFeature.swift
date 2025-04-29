//
//  HeartRateDetailsFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 25/04/2025.
//

import ComposableArchitecture
import Foundation
import HealthKit

@Reducer
struct HeartRateDetailsFeature {
    
    // MARK: - Properties
    
    var service: HeartRateDetailsService
    
    // MARK: - Lifecycle
    
    init(service: HeartRateDetailsService = DefaultHeartRateDetailsService()) {
        self.service = service
    }
    
    // MARK: - Reducer
    var body: some Reducer<State, Action> {
        CombineReducers {
            BindingReducer()
            Reduce { state, action in
                switch action {
                    
                    // MARK: - Binding
                case .binding(_):
                    //return .run { [min = state.scrollPositionStart] send  in
                    //    await send(.selectedChartMinChange(min))
                    //}
                    return .run { [date = state.rawSelectedDate]  send  in
                        if let date = date {
                            await send(.selectedChartDateChange(date))
                        } else {
                            await send(.selectedChartDateChange(nil))
                        }
                    }
                    
                    // MARK: - Actions
                    
                case let .selectedChartDateChange(date):
                    if date == nil {
                        state.selectedHeartRateMetric = nil
                    } else {
                        state.selectedHeartRateMetric = service.selectedHealthMetric(from: state.hrData, with: date)
                    }
                    return .none
                    
                case .fetchData:
                    return .run { [workout = state.workout] send in
                        await send(.calculateActiveEnergyBurned(workout))
                        await send(.updateData(Result {
                            try await service.fetchHeartRateSamples(for: workout)
                        }))
                    }
                    
                case let .updateData(.success(data)):
                    state.sample = data
                    return .run { send in
                        await send(.calculateMinuteHRStats)
                    }
                    
                case let .updateData(.failure(error)):
                    print("❌ Failed to sample data: \(error.localizedDescription)")
                    return .none
                
                case let .calculateActiveEnergyBurned(data):
                    return .run { send in
                       let energyBurned = try await service.fetchActiveEnergyBurned(for: data)
                        await send(.updateActiveEnergyBurned(energyBurned))
                    }
                    
                case let .updateActiveEnergyBurned(data):
                    state.activeEnergyBurned = data
                    return .none
                    
                case .calculateMinuteHRStats:
                    return .run { [sample = state.sample] send in
                        let hrData = service.calculateMinuteHRStats(from: sample)
                        await send(.updateHRMetric(hrData))
                    }
                    
                case let .updateHRMetric(data):
                    state.hrData = data
                    state.lowestMinHR = data.map(\.minHR).min() ?? 0
                    state.highestMaxHR = data.map(\.maxHR).max() ?? 0
                    
                    //state.scrollPositionStart = data.first?.minute ?? .now
                    
                    //return .run { [min = state.scrollPositionStart] send  in
                    //    await send(.selectedChartMinChange(min))
                    //}
                    return .none
                    
                case let .selectedChartMinChange(min):
                    //if let min = min {
                    //    print(min.formatted(.dateTime.minute()))
                    //}
                    return .none
                    
                    // MARK: - ViewActions
                case .view(.viewDidAppear):
                    return .run { send in //[start = state.scrollPositionStart] send in
                        //print(start)
                        await send(.fetchData)
                    }
     
                }
            }
        }
    }
    
}
