//
//  AppFeatureAW.swift
//  WorkoutMirror Watch App
//
//  Created by Sebastian Sciuba on 25/03/2026.
//

import ComposableArchitecture
import SharedModels
import HealthKit

/// Root feature of the WorkoutMirror Watch App.
///
/// Listens for incoming `WatchWorkoutEvent` messages from the paired iPhone
/// and drives navigation to `HRMirrorFeature` when a workout session starts.
///
/// Responsibilities:
/// - Responding to `.workoutStarted` by presenting `HRMirrorFeature`
/// - Forwarding pause/resume events to the active `HRMirrorFeature`
/// - Sending `.stop` to `HRMirrorFeature` before dismissing it so that
///   `WatchWorkoutSessionClient` properly ends the `HKWorkoutSession`
@Reducer
struct AppFeatureAW {

    // MARK: - Dependency

    @Dependency(\.watchConnectivityClientAW) var watchClient

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            // MARK: - Internal Actions

            case .watchEventReceived(.workoutStarted(let activityTypeRaw, let elapsed, let maxHR)):
                let activityType = HKWorkoutActivityType(rawValue: activityTypeRaw) ?? .other
                state.hrMirror = HRMirrorFeature.State(
                    elapsedSeconds: elapsed,
                    maxHeartRate: maxHR,
                    activityType: activityType
                )
                return .send(.hrMirror(.presented(.start)))

            case .watchEventReceived(.workoutPaused):
                guard state.hrMirror != nil else { return .none }
                return .send(.hrMirror(.presented(.workoutPaused)))

            case .watchEventReceived(.workoutResumed(let elapsed)):
                guard state.hrMirror != nil else { return .none }
                return .send(.hrMirror(.presented(.workoutResumed(elapsedSeconds: elapsed))))

            case .watchEventReceived(.workoutEnded):
                // Send .stop first so HRMirrorFeature can properly end the HKWorkoutSession
                // before TCA tears down the feature scope via ifLet.
                return .concatenate(
                    .send(.hrMirror(.presented(.stop))),
                    .run { send in
                        // Small delay to let endSession() complete before dismissing.
                        try? await Task.sleep(for: .milliseconds(300))
                        await send(.dismissHRMirror)
                    }
                )

            case .dismissHRMirror:
                state.hrMirror = nil
                return .none

            case .watchEventReceived(.workoutTick(let elapsed)):
                guard state.hrMirror != nil else { return .none }
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
