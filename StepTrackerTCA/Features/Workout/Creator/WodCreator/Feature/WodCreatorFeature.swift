//
//  WodCreatorFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 04/07/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels

@Reducer
struct WodCreatorFeature {
    
    // MARK: - Dependencies
    
    @Dependency(\.dismiss) var dismiss
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
                
                // MARK: - Binding
            case .binding(_):
                return .none
                
                // MARK: - Actions
            case let .wodTitleChanged(title):
                state.wodTitle = title
                return .none
                
            case let .durationChanged(duration):
                state.selectedDuration = duration
                return .none
                
            case let .exerciseWorkoutType(type):
                state.selectedExerciseWorkoutType = type
                return .none
                
            case let .roundsChange(rounds):
                state.selectedRounds = rounds
                return .none
                
            case let .weightMenChange(weight):
                state.weightMen = weight
                return .none
                
            case let .weightWomenChange(weight):
                state.weightWomen = weight
                return .none
                
            case let .wodInfoChanged(info):
                state.info = info
                return .none
                
                
            case let .exerciseTypeChange(exercise):
                state.selectedExerciseType = exercise
                return .none
                
            case let .repsChange(rep):
                state.selectedReps = rep
                return .none
                
            case .changeDurationPickerState:
                state.isDurationPickerToggle.toggle()
                return .none
                
            case .changeRoundsPickerState:
                state.isRoundsPickerPresented.toggle()
                return .none
                
            case .changeRepsPickerState:
                state.isRepsPickerPresented.toggle()
                return .none
                // MARK: - View Actions
            case .view(.viewDidAppear):
                return .none
                
            case .view(.wodTitleSheetTapped):
                state.isWodTitleSheetPresented.toggle()
                return .none
                
            case .view(.wodTitleSheetDismissed):
                state.isWodTitleSheetPresented = false
                return .none

            case .view(.wodInfoButtonTapped):
                state.isWodInfoSheetPresented.toggle()
                return .none
                
            case .view(.wodInfoSheetDismissed):
                state.isWodInfoSheetPresented = false
                return .none
                
            case .view(.workoutTypeTapped):
                state.isExerciseWorkoutTypePresented.toggle()
                return .none
                
            case .view(.durationPickerTapped):
                return .run { send in
                    await send(.changeDurationPickerState, animation: .easeInOut(duration: 0.3))
                }
                
            case .view(.roundsPickerTapped):
                return .run { send in
                    await send(.changeRoundsPickerState, animation: .easeInOut(duration: 0.3))
                }
                
                
            case .view(.repsPickerTapped):
                return .run { send in
                    await send(.changeRepsPickerState, animation: .easeInOut(duration: 0.3))
                }
            
            case .view(.addExerciseTapped):
                state.addExercise.toggle()
                return .none

            case .view(.addToExercises):
                let newExercise = ExerciseSession(
                    type: state.selectedExerciseType,
                    target: .reps(state.selectedReps),
                    weight: {
                        let menWeight = Int(state.weightMen)
                        let womenWeight = Int(state.weightWomen)
                        
                        if menWeight != nil || womenWeight != nil {
                            return WeightConfiguration(
                                men: menWeight,
                                women: womenWeight
                            )
                        } else {
                            return nil
                        }
                    }(),
                    info: state.info.isEmpty ? nil : state.info
                )
                state.exercises.append(newExercise)
                
                return .none
                
            case .view(.saveButtonTapped):
                
                let traningSession = WorkoutSessionNew(
                    name: state.wodTitle.isEmpty ? "WOD 1" : state.wodTitle,
                    type: state.exerciseWorkoutType,
                    timeCap: state.selectedDuration,
                    rounds: state.selectedRounds,
                    exercises: state.exercises)
                
                dump(traningSession)
                
                return .none
            }
        }
    }
    
}
// MARK: - Action

/// Implementation of `WodCreatorFeature` action
extension WodCreatorFeature {
    
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        case binding(BindingAction<State>)
        
        // MARK: - Actions
        case wodTitleChanged(String)
        case durationChanged(Int)
        case exerciseWorkoutType(ExerciseWorkoutType)
        case roundsChange(Int)
        case exerciseTypeChange(ExerciseType)
        case changeDurationPickerState
        case changeRoundsPickerState
        case changeRepsPickerState
        case repsChange(Int)
        case weightMenChange(String)
        case weightWomenChange(String)
        case wodInfoChanged(String)
        
        // MARK: - View actions
        case view(View)
        
        enum View {
            case viewDidAppear
            case wodTitleSheetTapped
            case wodTitleSheetDismissed
            case wodInfoButtonTapped
            case wodInfoSheetDismissed
            
            // MARK: - Duration Actions
            case workoutTypeTapped
            case durationPickerTapped
            case roundsPickerTapped
            case repsPickerTapped
            
            case addExerciseTapped
            
            case addToExercises
            
            case saveButtonTapped
        }
    }
}

// MARK: - State

/// Implementation of `WodCreatorFeature` state
extension WodCreatorFeature {
    
    @ObservableState
    struct State {
        
        // MARK: Title Properties
        
        var isWodTitleSheetPresented: Bool = false
        var wodTitle: String = ""
        
        var selectedExerciseWorkoutType: ExerciseWorkoutType = .amrap
        var isExerciseWorkoutTypePresented: Bool = false
        
        // MARK: - Duration Properties
        var selectedDuration: Int = 15
        var isDurationPickerPresented: Bool = false
        var isDurationPickerToggle: Bool = false
        var availableDurations: [Int] = Array(1...50)
        
        var selectedRounds: Int = 3
        var isRoundsPickerPresented: Bool = false
        var availableRounds: [Int] = Array(0...50)
        
        var addExercise: Bool = false
        
        var selectedExerciseType: ExerciseType = .airSquat
        
        var selectedReps: Int = 3
        var isRepsPickerPresented: Bool = false
        var availableReps: [Int] = Array(1...100)
        
        var isWeightViewPresented: Bool = false
        var weightMen: String = ""
        var weightWomen: String = ""
        
        var isWodInfoSheetPresented: Bool = false
        var info: String = ""
        
        
        var exercises: [ExerciseSession] = []
        
    }
    
}
