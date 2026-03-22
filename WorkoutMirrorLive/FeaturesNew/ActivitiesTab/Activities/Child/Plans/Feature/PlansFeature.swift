//
//  PlansFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 01/02/2026.
//

import ComposableArchitecture
import Foundation
import IssueReporting
import SharedModels

@Reducer
struct PlansFeature {

    // MARK: - Dependencies

    @Dependency(\.trainingSessionClient) var client

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                // MARK: - View Action

            case .view(.viewDidAppear):
                state.viewState = .loading
                return .run { send in
                    do {
                        let sessions = try await client.fetchAll()
                        await send(.sessionsLoaded(sessions))
                    } catch {
                        reportIssue(error)
                        await send(.sessionsLoaded([]))
                    }
                }

            case let .sessionsLoaded(sessions):
                state.sessions = sessions
                state.viewState = .success
                return .none

            case .view(.addPlanTapped):
                state.destination = .addPlan(AddPlanFeature.State())
                return .none

            case let .view(.workoutTapped(session)):
                state.destination = .planDetail(PlanDetailFeature.State(trainingSession: session))
                return .none

                // MARK: - Destination

            case .destination(.presented(.addPlan(.delegate(.saved(let session))))):
                return .run { send in
                    do {
                        try await client.save(session)
                        let sessions = try await client.fetchAll()
                        await send(.sessionsLoaded(sessions))
                    } catch {
                        reportIssue(error)
                    }
                }

            case .destination(.presented(.planDetail(.delegate(.saved(let session))))):
                return .run { send in
                    do {
                        try await client.save(session)
                        let sessions = try await client.fetchAll()
                        await send(.sessionsLoaded(sessions))
                    } catch {
                        reportIssue(error)
                    }
                }

            case .destination(.presented(.planDetail(.delegate(.deleted(let id))))):
                return .run { send in
                    do {
                        try await client.delete(id)
                        let sessions = try await client.fetchAll()
                        await send(.sessionsLoaded(sessions))
                    } catch {
                        reportIssue(error)
                    }
                }

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
