//
//  ClassRecapFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 16/07/2026.
//

import ComposableArchitecture
import HealthHub
import HealthKit
import SharedModels
import SwiftUI

/// GymRoom class-recap domain of the Activity Details screen: place in the
/// class ranking, class points and the gym-location map (IOS-00104-C).
///
/// The map deliberately does NOT mount on data arrival — the PARENT sends
/// `.mountMap` only after every other section's load settled (plus a settle
/// delay), so MapKit never initializes its drawable mid-layout-churn.
@Reducer
struct ClassRecapFeature {

    // MARK: - Dependency

    @Dependency(\.classParticipationClient) var classParticipationClient

    // MARK: - State

    @ObservableState
    struct State {

        /// Color representing training readiness level, shared across features.
        @Shared(.inMemory(.readinessLevelColor))
        var color: Color = .gray

        /// The workout being displayed.
        var workout: HKWorkout

        /// Class attendance for this workout — `nil` when the workout wasn't part
        /// of a GymRoom class, then the whole section is hidden.
        var classParticipation: ClassParticipation?

        /// `loading` → spinner, `ready` → map, `unavailable` → no coordinates
        /// (the class address wasn't geocoded).
        var classMapState: ClassMapState = .loading

        enum ClassMapState: Equatable {
            case loading
            case ready
            case unavailable
        }

        /// Whether the stored recap carries gym coordinates for the map.
        var hasCoordinates: Bool {
            classParticipation?.latitude != nil && classParticipation?.longitude != nil
        }
    }

    // MARK: - Action

    @CasePathable
    enum Action {

        /// Command from the parent — fetches the stored recap from the DB.
        case load

        /// Command from the parent — mounts the map once the screen layout settled.
        case mountMap

        /// DB fetch finished — `nil` when the workout wasn't part of a class.
        case participationLoaded(ClassParticipation?)

        case delegate(Delegate)

        @CasePathable
        enum Delegate {

            /// Recap fetch settled. `hasRecap == false` → the parent starts the
            /// GPS-route load (mutual exclusion: a class workout never has one).
            case didLoad(hasRecap: Bool)
        }
    }

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case .load:
                return .run { [classParticipationClient, id = state.workout.uuid] send in
                    let participation = try? await classParticipationClient.fetchByHKWorkoutId(id)
                    await send(.participationLoaded(participation))
                }

            case let .participationLoaded(participation):
                state.classParticipation = participation
                if participation != nil, !state.hasCoordinates {
                    // Recap without coordinates — the map slot shows "no location".
                    state.classMapState = .unavailable
                }
                return .send(.delegate(.didLoad(hasRecap: participation != nil)))

            case .mountMap:
                // Guarded so a stray command can't flip an `unavailable` map.
                guard state.hasCoordinates, state.classMapState == .loading else { return .none }
                state.classMapState = .ready
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
