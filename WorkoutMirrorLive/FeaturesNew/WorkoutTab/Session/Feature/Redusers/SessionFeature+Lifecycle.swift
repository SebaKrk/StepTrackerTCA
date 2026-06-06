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
                               watchClient = watchConnectivityClient,
                               sessionClient] send in
                    await watchClient.initializeWatchConnectivity()
                    let watchStatus = await watchClient.checkWatchStatus()
                    Logger.session.info("viewDidAppear — watchStatus: \(watchStatus.rawValue), workout: \(workout.title)")

                    if watchStatus == .ready {
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
                        }
                    } else {
                        // iPhone-standalone: iPhone owns the HKWorkoutSession.
                        await send(.setWorkoutMode(.iPhoneStandalone))
                        await send(.sessionViewStateChange(.countdown))
                        Logger.session.info("iPhone-standalone mode — Watch unavailable (\(watchStatus.rawValue))")
                        try await sessionClient.selectedWorkout(workout.hkType)
                        Logger.session.info("selectedWorkout set → DefaultWorkoutManager.prepareWorkout() triggered")
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
                return .run { [sessionClient] send in
                    // One-shot wait — exit loop after first emit. mirroredSessionStartedStream
                    // emits Void once per session when iPhone receives the mirrored HKWorkoutSession
                    // from Watch via workoutSessionMirroringStartHandler.
                    for await _ in await sessionClient.mirroredSessionStartedStream() {
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
                // Propaguj do active joinLiveClass child żeby iPad widział identyczny %HR.
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
                            await sessionClient.sendLifecycleEventToWatch(.maxHRUpdated(value))
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
