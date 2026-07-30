//
//  SessionFeature+Lifecycle.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 2026-05-29.
//

import ComposableArchitecture
import Foundation
import HealthHub
import HealthKit
import OSLog
import SharedModels

extension SessionFeature {

    var lifecycleReducer: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case .view(.viewDidAppear):
                return .run { [workout = state.selectedWorkout,
                               trainingSession = state.trainingSession,
                               requestedDevice = state.requestedDevice,
                               watchClient = watchConnectivityClient,
                               bluetoothClient,
                               clock,
                               sessionClient,
                               holdsStrap = Self.holdsStrapConnection] send in
                    await watchClient.initializeWatchConnectivity()
                    let watchStatus = await watchClient.checkWatchStatus()
                    // Mode pick (final semantics, user decision 2026-07-09):
                    // - `.hrBelt` / `.iphone` / `.airPods` → LITERALLY the iPhone:
                    //   never Watch-primary, HR from HealthKit (a BLE sensor, or
                    //   AirPods Pro 3 on iOS 26). The picker tiles differ only in
                    //   user guidance — the session path is identical. Landing
                    //   on a "waiting for Apple Watch" screen was a recurring trap —
                    //   a paired-but-off-wrist Watch (e.g. on a charger) still
                    //   reports `.ready`, since that status only checks `isPaired`.
                    // - `.watch` → Watch-primary when the Watch is ready.
                    // - `nil` (plan start, no picker) → auto-detect: a CONNECTED BLE
                    //   strap wins over the Watch.
                    let useWatch: Bool
                    switch requestedDevice {
                    case .iphone?, .hrBelt?, .airPods?:
                        useWatch = false
                    case .watch?, .mirror?:
                        useWatch = watchStatus == .ready
                    case nil:
                        if watchStatus == .ready {
                            await bluetoothClient.initializeBluetooth()
                            // CoreBluetooth powers on asynchronously — on a cold start
                            // `retrieveConnectedPeripherals` before `.poweredOn` returns
                            // [] and would silently miss the strap. Wait briefly (≤500 ms)
                            // but never forever: with Bluetooth off the status stays
                            // not-ready and the workout must still start.
                            var attempts = 0
                            while await bluetoothClient.getCurrentStatus() != .ready, attempts < 5 {
                                try? await clock.sleep(for: .milliseconds(100))
                                attempts += 1
                            }
                            let connectedSensors = await bluetoothClient.checkConnectedDevicesFirst()
                            useWatch = connectedSensors.isEmpty
                            Logger.session.info("Auto device detect — hasBLESensor: \(!connectedSensors.isEmpty), btWaitAttempts: \(attempts)")
                        } else {
                            useWatch = false
                        }
                    }
                    Logger.session.info("viewDidAppear — watchStatus: \(watchStatus.rawValue), requestedDevice: \(String(describing: requestedDevice)), useWatch: \(useWatch), workout: \(workout.title)")

                    // Every NEW session start invalidates the old plan-link note —
                    // an abandoned earlier start must not "claim" this workout
                    // (review cluster A: false claiming). Writing a fresh note happens
                    // only at the actual mirroring start (below), so
                    // standalone and abandoned starts never leave a pending one behind.
                    do {
                        @Shared(.pendingPlanLink) var pendingPlanLink
                        if pendingPlanLink != nil {
                            $pendingPlanLink.withLock { $0 = nil }
                            Logger.session.notice("pendingPlanLink cleared — new session start invalidates it")
                        }
                    }

                    if useWatch {
                        // Watch-primary: iPhone does NOT start its own HKWorkoutSession.
                        // Watch starts the primary session and mirrors it to iPhone.
                        await send(.setWorkoutMode(.watchPrimary))
                        // Apple Fitness-style startup — show "waiting for Apple Watch" UI
                        // until the mirrored session signal arrives from HealthKit.
                        await send(.sessionViewStateChange(.waitingForWatch))
                        Logger.session.info("Watch-primary mode — launching Watch workout")
                        do {
                            try await sessionClient.startWatchWorkout(workout.hkType)
                            Logger.session.info("startWatchWorkout succeeded — subscribing to mirroredSessionStartedStream")
                            // Dispatch subscription as a separate effect so it lives outside
                            // this one-shot `viewDidAppear` Task and can be cancelled cleanly.
                            await send(.subscribeMirroredSessionStarted)
                        } catch {
                            // Watch launch failed — fall back to iPhone-standalone.
                            Logger.session.error("startWatchWorkout FAILED: \(error) — falling back to iPhone-standalone")
                            await send(.setWorkoutMode(.iPhoneStandalone))
                            await send(.sessionViewStateChange(.countdown))
                            try await sessionClient.selectedWorkout(workout.hkType)
                            // EXPERIMENT (IOS-00100-D) — same hold as the direct standalone path.
                            if holdsStrap {
                                let heldSensors = await bluetoothClient.holdHRSensorConnections()
                                await WorkoutFileLogger.shared.log("[Connection] EXPERIMENT hold (fallback): \(heldSensors) HR sensor(s) held")
                            }
                        }
                    } else {
                        // iPhone-standalone: iPhone owns the HKWorkoutSession.
                        await send(.setWorkoutMode(.iPhoneStandalone))
                        await send(.sessionViewStateChange(.countdown))
                        // Either the user picked iPhone/BLE, or no Watch is ready.
                        Logger.session.info("iPhone-standalone mode — requestedDevice: \(String(describing: requestedDevice)), watchStatus: \(watchStatus.rawValue)")
                        try await sessionClient.selectedWorkout(workout.hkType)
                        Logger.session.info("selectedWorkout set → iPhone session prepared")
                        // EXPERIMENT (IOS-00100-D): keep an app-side link to the strap
                        // so a mid-workout drop gets an instant pending reconnect.
                        if holdsStrap {
                            let heldSensors = await bluetoothClient.holdHRSensorConnections()
                            await WorkoutFileLogger.shared.log("[Connection] EXPERIMENT hold: \(heldSensors) HR sensor(s) held for the session")
                        }
                    }

                    await send(.controls(.setWorkoutType(workout)))
                    await send(.makeCalculationForSession)
                    await send(.summary(.setTrainingSession(trainingSession)))
                }

            case let .setWorkoutMode(mode):
                state.workoutMode = mode
                return .run { [sessionClient] _ in
                    await sessionClient.setWorkoutMode(mode)
                }

            case .subscribeMirroredSessionStarted:
                @Dependency(\.date.now) var now
                return .run { [sessionClient, trainingSession = state.trainingSession, now] send in
                    // One-shot wait — exit loop after first emit. mirroredSessionStartedStream
                    // emits Void once per session when iPhone receives the mirrored HKWorkoutSession
                    // from Watch via workoutSessionMirroringStartHandler.
                    for await _ in await sessionClient.mirroredSessionStartedStream() {
                        if let trainingSession {
                            // The Watch ACTUALLY started the session — only now is it worth
                            // remembering the plan intent (review cluster A: writing at
                            // viewDidAppear left a note behind after abandoned starts
                            // and in standalone, where nobody consumes it).
                            @Shared(.pendingPlanLink) var pendingPlanLink
                            $pendingPlanLink.withLock {
                                $0 = PendingPlanLink(trainingSessionId: trainingSession.id, workoutStartDate: now)
                            }
                            Logger.session.info("pendingPlanLink set — plan \(trainingSession.id) (mirrored session started)")
                        }
                        await send(.sessionViewStateChange(.countdown))
                        break
                    }
                }
                .cancellable(id: SessionWatchCancelID.mirroredSessionSignal)

            case .makeCalculationForSession:
                return .run { send in
                    // Fallback values when HK permission for age/sex is missing — without
                    // these the zone calculation defaults to .resting (every HR is "below 50%
                    // of 0 = resting") and the UI shows 0% / "SPOCZYNEK" forever. Defaults
                    // are conservative (age=30, sex=.notSet) and produce ~190 bpm max HR.
                    let age = (try? await personalDataClient.getAge()) ?? 30
                    let sex = (try? await personalDataClient.getBiologicalSex()) ?? .notSet
                    let maxHR = Int(maxHeartRateClient.fromAge(age, sex))
                    await WorkoutFileLogger.shared.log("[MaxHR] computed: \(maxHR) (age=\(age), sex=\(String(describing: sex)))")
                    await send(.setMaxHR(maxHR))
                }

            case let .setMaxHR(value):
                // Propagate to the active joinLiveClass child so the iPad sees the identical %HR.
                state.joinLiveClass?.maxHeartRate = value
                let isSessionActive = state.sessionState == .session
                let mode = state.workoutMode
                return .merge(
                    .send(.live(.setupMaxHeartRate(value))),
                    isSessionActive ? .run { [mode,
                                              sessionClient,
                                              watchClient = watchConnectivityClient] _ in
                        // Watch-primary: HK mirroring channel — reliable when WC is unreachable
                        // (per CLAUDE.md R2). iPhone-standalone: WC path (no mirrored session).
                        if mode == .watchPrimary {
                            _ = await sessionClient.sendLifecycleEventToWatch(.maxHRUpdated(value))
                        } else {
                            await watchClient.sendWorkoutEvent(.maxHRUpdated(value))
                        }
                    } : .none
                )

            default:
                return .none
            }
        }
    }
}
