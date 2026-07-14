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

            case .view(.importPlanTapped):
                state.destination = .importPlan(ImportPlanFeature.State())
                return .none

                // MARK: - Destination

            case .destination(.presented(.addPlan(.delegate(.saved(let session))))):
                return saveAndReload(session)

            case .destination(.presented(.planDetail(.delegate(.saved(let session))))):
                return saveAndReload(session)

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

            case let .destination(.presented(.importPlan(.delegate(.imported(session))))):
                return saveAndReload(session)

            case .destination(.presented(.planDetail(.delegate(.startWorkout(let session))))):
                state.destination = nil
                let workout = WorkoutType(hkType: session.activity.hkType) ?? .cross
                state.destination = .session(
                    SessionFeature.State(
                        selectedWorkout: workout,
                        trainingSession: session,
                        countDown: CountDownFeature.State(workoutType: session.activity)
                    )
                )
                return .none

            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }

    // MARK: - Effects

    /// Persists a plan then reloads the list. Shared by the add, edit, and import
    /// flows — all three deliver a `TrainingSession` to save and expect a refresh.
    private func saveAndReload(_ session: TrainingSession) -> Effect<Action> {
        .run { send in
            do {
                try await client.save(session)
                let sessions = try await client.fetchAll()
                await send(.sessionsLoaded(sessions))
            } catch {
                reportIssue(error)
            }
        }
    }

}
