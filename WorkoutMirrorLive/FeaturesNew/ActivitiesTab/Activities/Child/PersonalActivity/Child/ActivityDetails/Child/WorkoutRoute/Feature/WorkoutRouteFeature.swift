//
//  WorkoutRouteFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 16/07/2026.
//

import ComposableArchitecture
import CoreLocation
import HealthKit
import SharedModels
import SwiftUI

/// GPS-route domain of the Activity Details screen: polyline for outdoor
/// workouts, a single pin for one-coordinate workouts, nothing for indoor.
///
/// The load is triggered by the PARENT (never on its own): a workout with a
/// GymRoom class recap can't have a route (mutual exclusion), so the parent
/// only sends `.load` when the recap fetch came back empty.
@Reducer
struct WorkoutRouteFeature {

    // MARK: - Dependency

    @Dependency(\.activityClient) var activityClient

    // MARK: - State

    @ObservableState
    struct State {

        /// Color representing training readiness level, shared across features.
        @Shared(.inMemory(.readinessLevelColor))
        var color: Color = .gray

        /// The workout being displayed.
        var workout: HKWorkout

        /// Full workout location data
        /// - `nil`: not loaded yet
        /// - `[]`: indoor workout (no location)
        /// - `[coordinate]`: single location (show pin)
        /// - `[coord1, coord2, ...]`: route (draw polyline)
        var routeCoordinates: [CLLocationCoordinate2D]?

        /// Whether location data is currently loading — drives the spinner card.
        var isLoadingLocation = false
    }

    // MARK: - Action

    @CasePathable
    enum Action {

        /// Command from the parent — starts the HealthKit route query.
        case load

        /// Route loaded (empty array = indoor workout / query error).
        case locationDataLoaded([CLLocationCoordinate2D])

        case delegate(Delegate)

        @CasePathable
        enum Delegate {

            /// The route load settled (successfully or not).
            case didFinishLoading
        }
    }

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case .load:
                state.isLoadingLocation = true
                return .run { [activityClient, workout = state.workout] send in
                    do {
                        let locations = try await activityClient.fetchWorkoutRoute(workout)
                        let coordinates = locations.map { $0.coordinate }
                        await send(.locationDataLoaded(coordinates))
                    } catch {
                        // Empty array on failure — same UI as an indoor workout.
                        await send(.locationDataLoaded([]))
                    }
                }

            case let .locationDataLoaded(coordinates):
                state.routeCoordinates = coordinates
                state.isLoadingLocation = false
                return .send(.delegate(.didFinishLoading))

            case .delegate:
                return .none
            }
        }
    }
}
