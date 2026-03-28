//
//  AppFeatureAW.swift
//  WorkoutMirror Watch App
//
//  Created by Sebastian Sciuba on 25/03/2026.
//

import ComposableArchitecture
import SharedModels

/// Root feature of the WorkoutMirror Watch App.
///
/// Listens for incoming `WatchWorkoutEvent` messages from the paired iPhone
/// and drives navigation to `HRMirrorFeature` when a workout session starts.
///
/// Responsibilities:
/// - Responding to `.workoutStarted` by presenting `HRMirrorFeature`
/// - Forwarding pause/resume events to the active `HRMirrorFeature`
/// - Dismissing `HRMirrorFeature` when the workout ends (from iPhone or Watch button)
@Reducer
struct AppFeatureAW {

    // MARK: - Dependency

    @Dependency(\.watchConnectivityClientAW) var watchClient

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            // MARK: - Internal Actions

            case .watchEventReceived(.workoutStarted(_, let elapsed, let maxHR)):
                state.hrMirror = HRMirrorFeature.State(elapsedSeconds: elapsed, maxHeartRate: maxHR)
                return .none

            case .watchEventReceived(.workoutPaused):
                return .send(.hrMirror(.presented(.workoutPaused)))

            case .watchEventReceived(.workoutResumed(let elapsed)):
                return .send(.hrMirror(.presented(.workoutResumed(elapsedSeconds: elapsed))))

            case .watchEventReceived(.workoutEnded):
                state.hrMirror = nil
                return .none

            case .watchEventReceived(.workoutTick(let elapsed)):
                return .send(.hrMirror(.presented(.workoutTick(elapsedSeconds: elapsed))))

            case .watchEventReceived(.maxHRUpdated(let maxHR)):
                state.hrMirror?.maxHeartRate = maxHR
                return .none

            case .watchEventReceived(.hrReading):
                // iPhone-originated HR readings are not relevant on the Watch side.
                return .none

            // MARK: - View Actions

            case .view(.onAppear):
                return .run { [watchClient = watchClient] send in
                    for await event in watchClient.incomingEventStream() {
                        await send(.watchEventReceived(event))
                    }
                }

            // MARK: - Child Actions

            case .hrMirror:
                return .none
            }
        }
        .ifLet(\.$hrMirror, action: \.hrMirror) {
            HRMirrorFeature()
        }
    }
}
