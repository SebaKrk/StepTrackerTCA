//
//  WorkoutCreatorFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 04/07/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels
import WorkoutKit

@Reducer
struct WorkoutCreatorFeature {
    
    // MARK: - Dependencies
    
    @Dependency(\.dismiss) var dismiss
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce {
            state,
            action in
            switch action {
                
                // MARK: - Binding
            case .binding(_):
                return .none
                
                // MARK: - Actions
            case let .workoutTitleChanged(title):
                state.workoutTitle = title
                return .none
                
            case let .selectedWorkoutActivityPickerChange(item):
                state.workoutActivityType = item
                return .none
                
            case let .selectedWorkoutLocationPickerChange(item):
                state.workoutLocationType = item
                return .none
                
            case let .addWodToWods(WOD):
                state.wods.append(WOD)
                return .none
                
                // MARK: - View Actions
                
            case .view(.cancelButtonTapped):
                return .run { send in
                    await self.dismiss()
                }
                
            case .view(.workoutTitleSheetTapped):
                state.isWorkoutTitleSheetPresented.toggle()
                return .none
                
            case .view(.workoutTitleSheetDismissed):
                state.isWorkoutTitleSheetPresented = false
                return .none
                
            case .view(.wodSheetTapped):
                state.destination = .openWodCreator(WodCreatorFeature.State())
                return .none
                
            case .view(.openWarmUpSheetPresented):
                if let warmUp = state.warmUpSession {
                    state.destination = .openSessionConfiguration(SessionConfigurationFeature.State(
                        phaseType: .warmUp,
                        warmUpSession: warmUp
                    ))
                } else {
                    state.destination = .openSessionConfiguration(SessionConfigurationFeature.State(phaseType: .warmUp)
                    )
                }
                return .none
                
            case .view(.openCoolDownSheetPresented):
                if let coolDown = state.coolDownSession {
                    state.destination = .openSessionConfiguration(SessionConfigurationFeature.State(
                        phaseType: .coolDown,
                        coolDownSession: coolDown)
                    )
                } else {
                    state.destination = .openSessionConfiguration(SessionConfigurationFeature.State(phaseType: .coolDown))
                }
                return .none
                
            case .view(.previewButtonTapped):
                guard let activityType = state.workoutActivityType else {
                    return .none
                }
                
                let newSession = TrainingSession(
                    date: .now,
                    title: state.workoutTitle,
                    activity:  activityType,
                    location: state.workoutLocationType,
                    warmUp: state.warmUpSession,
                    workouts: state.wods,
                    coolDown: state.coolDownSession
                )
                
                state.trainingSession = newSession
                
                if let session = state.trainingSession {
                    state.destination = .openWorkoutPreview(WorkoutPreviewFeature.State(trainingSession: session))
                }
                return .none
                
            case .view(.workoutTypeButtonTaped):
                state.destination = .openWorkoutActivityType(WorkoutActivityTypeFeature.State())
                return .none
                
            case .view(.debugButtonTaped):
                let debugSession = TrainingSession.previewTrainingSession
                let x = TrainingSession(
                    date: .now ,
                    title: "Dekerta Crossfit - WeightLifting",
                    activity: .crossTraining,
                    location: .indoor,
                    warmUp: WarmUpSession(
                        goal: .timeLimit,
                        time: 20,
                        description: "WarmUp for Snatch"
                    ),
                    workouts: [
                        WorkoutSessionNew(
                            name: "WOD 1",
                            type: .forTime,
                            timeCap: 20,
                            rounds: 0,
                            exercises: [
                                ExerciseSession(
                                    type: .snatch,
                                    target: .reps(1),
                                    weight: nil,
                                    info: "Find one rep max in 20 min time"
                                )
                            ]
                        )
                    ],
                    coolDown: CoolDownSession(
                        goal: .timeLimit,
                        time: 10,
                        description: "Strenig after have weightlifting"
                    )
                )
                
                state.trainingSession = debugSession
                
                if let session = state.trainingSession {
                    state.destination = .openWorkoutPreview(WorkoutPreviewFeature.State(trainingSession: session))
                }
                return .none
                
                // MARK: - Destination
            case let .destination(.presented(.openWodCreator(.delegate(.wodCreated(workout))))):
                return .run { send in
                    await send(.addWodToWods(workout))
                }
                
            case let  .destination(.presented(.openWorkoutActivityType(.delegate(.workoutActivityTypeUpdated(update))))):
                state.workoutActivityType = update
                
                return .run { send in
                    await send(.destination(.dismiss))
                }
                
            case let .destination(.presented(.openSessionConfiguration(.delegate(.warmUpUpdated(session))))):
                state.warmUpSession = session
                return .none
                
            case let .destination(.presented(.openSessionConfiguration(.delegate(.coolDownUpdated(session))))):
                state.coolDownSession = session
                return .none
                
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}
