//
//  WorkoutSubmissionStrategy.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 11/04/2025.
//

import Foundation

// strategy
protocol WorkoutSubmissionStrategy {
    func submit(
        workout: WorkoutType,
        movement: String,
        date: Date,
        value: String,
        unit: String
    ) async throws
}

// Strategy - Submit
struct SubmitWorkoutStrategy: WorkoutSubmissionStrategy {
    
    let service: SubmitWorkoutService
    
    func submit(workout: WorkoutType, movement: String, date: Date, value: String, unit: String) async throws {
        try await service.submitWorkout(for: workout, movement, date: date, value: value, unit: unit)
    }
}

// Strategy add Goal
struct SetGoalStrategy: WorkoutSubmissionStrategy {
    
    let service: SetEditGoalService

    func submit(workout: WorkoutType, movement: String, date: Date, value: String, unit: String) async throws {
        try await service.setNewGoal(for: workout, movement, date: date, value: value, unit: unit)
    }
}


// Factory
enum Service {
    case submit
    case setGoal
}

protocol WorkoutSubmissionStrategyFactory {
    func strategy(for service: Service) -> WorkoutSubmissionStrategy
}

struct DefaultWorkoutSubmissionStrategyFactory: WorkoutSubmissionStrategyFactory {
    func strategy(for service: Service) -> WorkoutSubmissionStrategy {
        switch service {
        case .setGoal:
            return SetGoalStrategy(service: DefaultSetEditGoalService())
        case .submit:
            return SubmitWorkoutStrategy(service: DefaultSubmitWorkoutService())
        }
    }
}

// DependencyKey
private enum WorkoutSubmissionStrategyFactoryKey: DependencyKey {
    static var liveValue: WorkoutSubmissionStrategyFactory = DefaultWorkoutSubmissionStrategyFactory()
}

extension DependencyValues {
    var workoutSubmissionStrategyFactory: WorkoutSubmissionStrategyFactory {
        get { self[WorkoutSubmissionStrategyFactoryKey.self] }
        set { self[WorkoutSubmissionStrategyFactoryKey.self] = newValue }
    }
}

import ComposableArchitecture

@Reducer
struct WorkoutSubmissionFeature {
    
    // MARK: - Dependency
    
    @Dependency(\.workoutSubmissionStrategyFactory) var strategyFactory
    
    @Dependency(\.dismiss) var dismiss
      
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state,action in
            switch action {
                
            case .addValue:
                return .run { [service = state.service, workoutType = state.workoutType] send in
                    let strategy = strategyFactory.strategy(for: service)
                    do {
                        try await strategy.submit(workout: workoutType , movement: "clean", date: .now, value: "123", unit: "kg")
                    } catch {
                        
                    }
                }
            
            case .view(.add):
                return .run { send in
                    await send(.addValue)
                }
                
            case .view(.viewDidAppear):
                print("WorkoutSubmissionFeature")
                return .none
            }
        }
    }
    
    @CasePathable
    enum Action: ViewAction {
        
        case addValue
        
        case view(View)
        
        enum View {
            case viewDidAppear
            case add
        }
    }
    
    @ObservableState
    struct State {
        
        var service: Service
        var workoutType: WorkoutType
    }
}

import SwiftUI

@ViewAction(for: WorkoutSubmissionFeature.self)
struct WorkoutSubmissionView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<WorkoutSubmissionFeature>
    
    // MARK: - View
    
    var body: some View {
        HStack {
            Text("WorkoutSubmissionFeature")
            Button {
                send(.add)
            } label: {
                Text("add")
            }
        }
        .onAppear {
            send(.viewDidAppear)
        }
        
    }
    
}
