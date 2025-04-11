//
//  ScoresFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 14/03/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct ScoresFeature {
    
    // MARK: - Dependencies
    
    @Dependency(\.scoresFeatureServices) var services: ScoresFeatureServices

    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state,action in
            switch action {
                
                // MARK: - Action
                
            case let .getData(for: workoutType):
                return .run { send in
                    do  {
                        let summary = try await services.fetchSummary(for: workoutType)
                        await send(.updateData(summary))
                    } catch {
                        print("Error fetching workout data: \(error)")
                    }
                }
                
            case let .updateData(summary):
                state.summary = summary
                return .run { send in
                    await send(.mapToGroupedMovement(summary))
                    await send(.filteredMovements(summary))
                }
                
            case let .mapToGroupedMovement(summary):
                return .run { [workoutType = state.selectedWorkoutType] send in
                    let groupedMovement = services.mapToGroupedMovement(from: summary,
                                                                        workoutType: workoutType)
                    await send(.updateGroupedMovement(groupedMovement))
                }
                
            case let .updateGroupedMovement(groupedMovement):
                state.selectedMovement = groupedMovement
                return .none
                
            case let .filteredMovements(summary):
                return .run { send in
                    let filteredMovements = services.filterMovements(from: summary)
                    await send(.updateFilteredData(filteredMovements))
                }
                
            case let .updateFilteredData(data):
                state.filteredMovements = data
                return .none
                
                // MARK: - View Action
                
            case .view(.viewDidAppear):
                return .run { [workoutType = state.selectedWorkoutType] send in
                    await send(.getData(for: workoutType))
                }
                
            case let .view(.openExerciseInfo(movement)):
                state.destination = .openInfo(MovementInfoFeature.State(movement: movement))
                return .none
                
            case let .view(.openMovementDetails(movement)):
                if let data = state.selectedMovement {
                    state.destination = .showDetails(MovementDetailsFeature.State(movement: movement, selectedMovement: data))
                }
                return .none
                
            case .view(.goalsButtonTapped):
                return .run { send in
                    await send(.openGoalsSheet)
                }
                
            case .view(.submitWorkoutScoreButtonTapped):
                return .run { send in
                    await send(.openSubmitWorkoutSheet)
                }
                
                // MARK: - Destination
                
            case .openGoalsSheet:
                let workoutType = state.selectedWorkoutType
                state.destination = .openGoal(SetEditGoalFeature.State(workoutType: workoutType))
                return .none
                
            case .openSubmitWorkoutSheet:
                let workoutType = state.selectedWorkoutType
                state.destination = .openSubmitWorkout(SubmitWorkoutFeature.State(workoutType: workoutType))
                return .none
                
            case .destination(_):
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
    
    /// A structure used specifically for this feature and view.
    /// Represents a filtered movement containing relevant details such as
    /// the movement name, best performance, last performance, and a possible workout goal.
    struct FilteredMovement: Identifiable {
        /// A unique identifier for the movement.
        let id: String
        
        /// The name of the movement.
        let movement: String
        
        /// The best measurement recorded for the movement, if available.
        let best: WorkoutMeasurement?
        
        /// The most recent measurement recorded for the movement, if available.
        let last: WorkoutMeasurement?
        
        /// The goal associated with the movement, if available.
        let goal: WorkoutGoal?
    }
    
}
