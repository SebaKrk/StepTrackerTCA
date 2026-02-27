//
//  TrainingSessionEditorFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 21/02/2026.
//

import ComposableArchitecture
import SharedModels

@Reducer
struct TrainingSessionEditorFeature {

    // MARK: - Dependencies

    @Dependency(\.dismiss) var dismiss

    // MARK: - Body

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
                
            case .binding:
                return .none

            case .saveTapped:
                let session = TrainingSession(id: state.originalId,
                                              draft: state.draft)
                
                state.$plannedWorkouts.withLock { $0[id: session.id] = session }
                
                return .run { send in
                    await send(.delegate(.saved(session)))
                    await dismiss()
                }

            case .delegate:
                return .none
            }
        }
    }
}
