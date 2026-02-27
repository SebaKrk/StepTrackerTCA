//
//  AddPlanFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 01/02/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

@Reducer
struct AddPlanFeature {

    // MARK: - Dependencies

    @Dependency(\.dismiss) var dismiss

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

                // MARK: - View Action

            case .view(.dismissTapped):
                return .none

            case .view(.scanPlanTapped):
                state.destination = .scanPlan(ScanPlanFeature.State())
                return .none

            case .view(.manualEntryTapped):
                state.destination = .editor(TrainingSessionEditorFeature.State())
                return .none

                // MARK: - Destination

            case .destination(.presented(.editor(.delegate(.saved(let session))))):
                state.$plannedWorkouts.withLock { $0[id: session.id] = session }
                return .run { _ in await dismiss() }

            case .destination(.presented(.editor(.delegate(.deleted(let id))))):
                state.$plannedWorkouts.withLock { $0.remove(id: id) }
                return .run { _ in await dismiss() }

            case .destination(.presented(.scanPlan(.delegate(.saved(let session))))):
                state.$plannedWorkouts.withLock { $0[id: session.id] = session }
                return .run { _ in await dismiss() }

            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }

}
