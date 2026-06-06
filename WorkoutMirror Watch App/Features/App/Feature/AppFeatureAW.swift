//
//  AppFeatureAW.swift
//  WorkoutMirror Watch App
//
//  Created by Sebastian Sciuba on 25/03/2026.
//

import ComposableArchitecture
import OSLog
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
    @Dependency(\.watchWorkoutSessionClient) var watchWorkoutSessionClient

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            // MARK: - Internal Actions

            case .workoutConfigurationReceived(let activityType):
                // Fired by WatchAppDelegate.handle(_:) — before any WC event arrives.
                // Start HRMirrorFeature so it calls startMirroringToCompanionDevice(),
                // which automatically brings the Watch app to the foreground.
                guard state.hrMirror == nil else {
                    Logger.appAW.debug("workoutConfigurationReceived — hrMirror already active, ignoring")
                    return .none
                }
                Logger.appAW.info("workoutConfigurationReceived — activityType: \(activityType.rawValue)")
                state.hrMirror = HRMirrorFeature.State(activityType: activityType)
                return .send(.hrMirror(.presented(.start)))

            case .watchEventReceived(.workoutStarted(let activityTypeRaw, let elapsed, let maxHR)):
                let hrMirrorActive = state.hrMirror != nil
                Logger.appAW.info("watchEventReceived: .workoutStarted — activityType=\(activityTypeRaw), hrMirrorActive=\(hrMirrorActive)")
                let activityType = HKWorkoutActivityType(rawValue: activityTypeRaw) ?? .other

                if state.hrMirror != nil {
                    // Already started via handleWorkoutConfiguration — only sync params.
                    state.hrMirror?.maxHeartRate = maxHR
                    state.hrMirror?.elapsedSeconds = elapsed
                    return .none
                }

                // Fallback: Watch app was already running (e.g. manually opened by user).
                state.hrMirror = HRMirrorFeature.State(
                    elapsedSeconds: elapsed,
                    maxHeartRate: maxHR,
                    activityType: activityType
                )
                return .send(.hrMirror(.presented(.start)))

            case .watchEventReceived(.countdownStart):
                guard state.hrMirror != nil else { return .none }
                return .send(.hrMirror(.presented(.countdownStart)))

            case .watchEventReceived(.countdownFinished):
                guard state.hrMirror != nil else { return .none }
                return .send(.hrMirror(.presented(.countdownFinished)))

            case .watchEventReceived(.workoutPaused):
                guard state.hrMirror != nil else { return .none }
                return .send(.hrMirror(.presented(.workoutPaused)))

            case .watchEventReceived(.workoutResumed(let elapsed)):
                guard state.hrMirror != nil else { return .none }
                return .send(.hrMirror(.presented(.workoutResumed(elapsedSeconds: elapsed))))

            case .watchEventReceived(.workoutEnded):
                Logger.appAW.info("watchEventReceived: .workoutEnded — stopping HRMirrorFeature")
                return .send(.hrMirror(.presented(.stop)))

            case .dismissHRMirror:
                Logger.appAW.info("dismissHRMirror — tearing down HRMirrorFeature")
                state.hrMirror = nil
                return .none

            case .stuckSessionDetected(let stuck):
                Logger.appAW.notice("stuck session detected — activityType=\(stuck.activityTypeRaw), startDate=\(stuck.startDate)")
                let activityTypeRaw = stuck.activityTypeRaw
                let startDate = stuck.startDate
                Task {
                    await WorkoutFileLogger.shared.log("[Recovery] alert shown — activityType=\(activityTypeRaw), startDate=\(startDate)")
                }
                state.recoveryAlert = AlertState {
                    TextState(String(localized: "Unfinished workout detected"))
                } actions: {
                    ButtonState(action: .endTapped) {
                        TextState(String(localized: "End now"))
                    }
                    ButtonState(role: .destructive, action: .discardTapped) {
                        TextState(String(localized: "Discard"))
                    }
                } message: {
                    TextState(String(localized: "Workout started: \(stuck.startDate.formatted(date: .omitted, time: .shortened))"))
                }
                return .none

            case .recoveryAlert(.presented(.endTapped)):
                Logger.appAW.info("recoveryAlert — user chose End")
                return .run { [watchWorkoutSessionClient, watchClient = watchClient] send in
                    await WorkoutFileLogger.shared.log("[Recovery] user chose END — saving HKWorkout")
                    await watchWorkoutSessionClient.recoverAndEnd()
                    await watchClient.transferLogFile()
                    await send(.recoveryAlert(.dismiss))
                }

            case .recoveryAlert(.presented(.discardTapped)):
                Logger.appAW.info("recoveryAlert — user chose Discard")
                return .run { [watchWorkoutSessionClient, watchClient = watchClient] send in
                    await WorkoutFileLogger.shared.log("[Recovery] user chose DISCARD — workout discarded")
                    await watchWorkoutSessionClient.recoverAndDiscard()
                    await watchClient.transferLogFile()
                    await send(.recoveryAlert(.dismiss))
                }

            case .recoveryAlert:
                return .none

            case .watchEventReceived(.workoutTick(let elapsed)):
                guard state.hrMirror != nil else { return .none }
                return .send(.hrMirror(.presented(.workoutTick(elapsedSeconds: elapsed))))

            case .watchEventReceived(.maxHRUpdated(let maxHR)):
                state.hrMirror?.maxHeartRate = maxHR
                return .none

            case .watchEventReceived(.workoutSaved(_)):
                // Watch-originated — not relevant on the Watch side.
                return .none

            case .hrMirror(.presented(.delegate(.didFinishSaving))):
                Logger.appAW.info("didFinishSaving — dismissing HRMirrorFeature")
                return .send(.dismissHRMirror)

            // MARK: - View Actions

            case .view(.onAppear):
                return .merge(
                    .run { [watchClient = watchClient] send in
                        for await event in watchClient.incomingEventStream() {
                            await send(.watchEventReceived(event))
                        }
                    },
                    // Parallel stream from the HK mirroring channel
                    // (`didReceiveDataFromRemoteWorkoutSession`). Used for `.workoutEnded`
                    // from iPhone in Watch-primary mode — reliable when WC is unreachable.
                    // Duplicate delivery (WC + HK) is idempotent — `HRMirrorFeature.stop`
                    // sets `isSaving = true` and subsequent dispatches early-return.
                    .run { [watchWorkoutSessionClient] send in
                        for await event in watchWorkoutSessionClient.remoteEventStream() {
                            await send(.watchEventReceived(event))
                        }
                    },
                    // Listen for workout configurations forwarded by WatchAppDelegate.handle(_:).
                    // This stream fires when iPhone calls startWatchApp(toHandle:) — before
                    // any WatchConnectivity event is delivered.
                    .run { send in
                        for await activityType in WorkoutConfigurationStream.shared.stream {
                            await send(.workoutConfigurationReceived(activityType))
                        }
                    },
                    // One-shot recovery check: if a previous app run left a stuck HKWorkoutSession
                    // in HealthKit, present an alert so the user can finalize or discard it.
                    .run { [watchWorkoutSessionClient] send in
                        await WorkoutFileLogger.shared.log("[Recovery] app launch — running stuck session check")
                        guard let stuck = await watchWorkoutSessionClient.checkForStuckSession() else { return }
                        await send(.stuckSessionDetected(stuck))
                    },
                    // One-shot: transfer ALL historical watch_log_*.txt files to iPhone.
                    // Picks up logs from sessions that never reached normal .stop flow (crashes, low battery).
                    .run { [watchClient = watchClient] _ in
                        await watchClient.transferAllLogFiles()
                    }
                )

            // MARK: - Child Actions

            case .hrMirror:
                return .none
            }
        }
        .ifLet(\.$hrMirror, action: \.hrMirror) {
            HRMirrorFeature()
        }
        .ifLet(\.$recoveryAlert, action: \.recoveryAlert)
    }
}
