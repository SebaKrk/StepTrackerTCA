//
//  PlansFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 01/02/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

@Reducer
struct PlansFeature {

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                // MARK: - View Action

            case .view(.viewDidAppear):
                return .none

            case .view(.addPlanTapped):
                state.destination = .addPlan(AddPlanFeature.State())
                return .none

            case let .view(.workoutTapped(session)):
                state.destination = .planDetail(PlanDetailFeature.State(trainingSession: session))
                return .none

                // MARK: - Destination

            case .destination(.presented(.addPlan(.delegate(.saved(let session))))):
                state.$plannedWorkouts.withLock { $0[id: session.id] = session }
                return .none

            case .destination(.presented(.planDetail(.delegate(.saved(let session))))):
                state.$plannedWorkouts.withLock { $0[id: session.id] = session }
                return .none

            case .destination(.presented(.planDetail(.delegate(.deleted(let id))))):
                state.$plannedWorkouts.withLock { $0.remove(id: id) }
                return .none

            case .destination(.presented(.planDetail(.delegate(.startWorkout(let session))))):
                state.destination = nil
                let workout = WorkoutType(hkType: session.activity.hkType) ?? .cross
                state.destination = .session(
                    SessionFeature.State(selectedWorkout: workout, trainingSession: session)
                )
                return .none

            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }

}
