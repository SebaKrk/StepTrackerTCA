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

        /// User's maximum heart rate — forwarded to the drill-in for the
        /// zone-colored route polyline.
        var maxHeartRate: Double

        /// Full workout location data (kept as `CLLocation` — the drill-in
        /// derives max speed from the samples)
        /// - `nil`: not loaded yet
        /// - `[]`: indoor workout (no location)
        /// - `[location]`: single location (show pin)
        /// - `[loc1, loc2, ...]`: route (draw polyline)
        var routeLocations: [CLLocation]?

        /// Whether location data is currently loading — drives the spinner card.
        var isLoadingLocation = false

        /// Route drill-in (full map + distance stats), pushed from the tile header.
        @Presents var routeDetails: RouteDetailsFeature.State?
    }

    // MARK: - Action

    @CasePathable
    enum Action {

        /// Command from the parent — starts the HealthKit route query.
        case load

        /// Route loaded (empty array = indoor workout / query error).
        case locationDataLoaded([CLLocation])

        /// Tile header (chevron) tapped — pushes the route drill-in.
        case routeDetailsTapped

        /// Delegates to the route drill-in presentation lifecycle.
        case routeDetails(PresentationAction<RouteDetailsFeature.Action>)

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
                        await send(.locationDataLoaded(locations))
                    } catch {
                        // Empty array on failure — same UI as an indoor workout.
                        await send(.locationDataLoaded([]))
                    }
                }

            case let .locationDataLoaded(locations):
                state.routeLocations = locations
                state.isLoadingLocation = false
                return .send(.delegate(.didFinishLoading))

            case .routeDetailsTapped:
                guard let locations = state.routeLocations, locations.count >= 2 else { return .none }
                state.routeDetails = RouteDetailsFeature.State(
                    workout: state.workout,
                    locations: locations,
                    maxHeartRate: Int(state.maxHeartRate)
                )
                return .none

            case .routeDetails:
                return .none

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$routeDetails, action: \.routeDetails) {
            RouteDetailsFeature()
        }
    }
}
