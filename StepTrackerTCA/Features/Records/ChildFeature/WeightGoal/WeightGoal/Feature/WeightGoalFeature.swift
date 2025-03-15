//
//  WeightGoalFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 24/01/2025.
//

import ComposableArchitecture
import Foundation
import Combine

@Reducer
struct WeightGoalFeature {
    
    // MARK: - Dependencies
    
    let weightGoalService: WeightGoalService

    // MARK: - Livecycle
    
    init(service: WeightGoalService) {
        self.weightGoalService = service
    }
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
                // MARK: - Actions
            case .observer:
                //print("🟡 Rozpoczynam subskrypcję na zmiany w Core Data")
                return .publisher {
                    weightGoalService.itemsDidChangePublisher()
                        .receive(on: DispatchQueue.main)
                        .handleEvents(receiveOutput: { _ in
                            print("🔄 Otrzymano zdarzenie o zmianie, pobieram nową wagę")
                        })
                        .map { _ in .fetchWeightGoal }
                }
                .cancellable(id: CancelID.observeWeightGoal, cancelInFlight: false)
                
            case .checkWeightGoal:
                if state.weightGoal == nil {
                    return .run { send in
                        await send(.fetchWeightGoal)
                    }
                }
                return .none
                
            case .fetchWeightGoal:
                return .run { send in
                    do  {
                        let goal = try await weightGoalService.fetchWeightGoal()
                        await send(.updateWeightGoal(goal: goal))
                    } catch {
                        print("error fetchWeightGoal \(error)")
                    }
                }
                
            case let .updateWeightGoal(goal):
                state.weightGoal = goal
                return .none
                
                // MARK: - View Actions
                
            case .view(.navigationButtonTapped):
                return .send(.show)
                
            case .view(.viewDidAppear):
                //print("👀 Widok się pojawił, subskrybuję zmiany w Core Data")
                return .run { send in
                    await send(.checkWeightGoal)
                    await send(.observer)
                }
            
                // MARK: - Destination
                
            case .show:
                state.destination = .setWeightGoal(SetWeightGoalFeature.State())
                return .none
                
            case let .destination(.presented(.setWeightGoal(.delegate(.setGoal(data))))):
                state.weightGoal = data
                return .none
                
            default: return .none      
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
    
}
