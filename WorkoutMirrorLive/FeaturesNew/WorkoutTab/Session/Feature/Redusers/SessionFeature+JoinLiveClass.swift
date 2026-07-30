//
//  SessionFeature+JoinLiveClass.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 2026-05-29.
//

import ComposableArchitecture
import Foundation
import OSLog
import SharedModels

extension SessionFeature {

    var joinLiveClassReducer: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case .view(.joinLiveClassSheetDismissed):
                // Swipe-down / X — the broadcast CONTINUES, state stays alive.
                state.isJoinLiveClassSheetPresented = false
                return .none

            case .joinLiveClass(.delegate(.didDismiss)):
                // Sheet schowany (Join tapped / X / swipe-down) — broadcast TRWA,
                // state żyje, ikona toolbar dalej pokazuje connected.
                state.isJoinLiveClassSheetPresented = false
                return .none

            case .joinLiveClass(.delegate(.didLeave)):
                // User explicit zakończył klasę — kasuj state + ukryj sheet.
                state.joinLiveClass = nil
                state.isJoinLiveClassSheetPresented = false
                // Drop the class window origin — the next class starts a fresh window.
                state.classEntryZoneSnapshot = nil
                return .none

            case .joinLiveClass(.delegate(.joinedClass)):
                // Snapshot the effort origin on the FIRST join only — `joinedClass`
                // fires again on every reconnect, and resetting the baseline there
                // would zero out points earned before the drop.
                if state.classEntryZoneSnapshot == nil {
                    state.classEntryZoneSnapshot = state.live.effortPoints.secondsByZone
                }
                return .none

            case let .joinLiveClass(.delegate(.recapReceived(payload))):
                // Host przysłał wynik zajęć — parkuj pending class recap. Konsumpcja przy
                // zapisie treningu (`.workoutSaved`/`savedWorkoutFound`) w AppTabNewFeature.
                captureClassRecapSnapshot(payload, state)
                return .none

            case .joinLiveClass:
                return .none

            // Catch-all for `destination` presentation actions — composition happens
            // via `.ifLet(\.$destination, ...)` modifier on the body.
            case .destination(_):
                return .none

            // Terminal catch-alls for child feature actions whose state is handled
            // by their respective `Scope(state:action:)` reducers in the body.
            case .summary(.view(.endWorkoutButtonTapped)):
                return .none

            case .countDown(_):
                return .none

            case .live(.workoutMetrics), .live(.sensorFreshnessTick):
                // Bridge: feed the LiveSession effort counter into JoinLiveClass so
                // every BLE payload carries the athlete's CLASS points. Unlike the
                // on-screen counter (cumulative for the whole workout), the class
                // value is WINDOW-SCOPED: only effort since joining this class, so an
                // athlete who trained before it started enters the board at 0 like
                // everyone else. A one-tick lag vs the child reducer is harmless at 1 Hz.
                // `sensorFreshnessTick` included (IOS-00100-C): the stale flag can
                // flip without any metrics arriving (that's the point), and the
                // payloads must carry the truth from the next send on.
                // Read into locals first — reading `state.live` while mutating
                // `state.joinLiveClass` is an overlapping exclusive access.
                let windowPoints = state.classEntryZoneSnapshot.map {
                    EffortPointsScoring.points(from: state.live.effortPoints.secondsByZone, since: $0)
                } ?? 0
                let liveSensorStale = state.live.isSensorStale
                let liveWatchLinkLost = state.live.isWatchConnectionLost
                state.joinLiveClass?.currentEffortPoints = windowPoints
                state.joinLiveClass?.isSensorStale = liveSensorStale
                state.joinLiveClass?.watchLinkLost = liveWatchLinkLost
                return .none

            case .live(_):
                return .none

            case .controls(_):
                return .none

            case .summary(_):
                return .none

            default:
                return .none
            }
        }
    }

    // MARK: - Class recap snapshot

    /// Freezes the iPad recap into `@Shared(.pendingClassRecap)`, combining the BLE
    /// payload (place, count, coordinates, classSessionId) with locally-known values:
    /// `gymName` from the scanned QR and the class points from the on-device
    /// window-scoped counter. `AppTabNewFeature` links it to the `HKWorkout` when the
    /// workout is saved (same hook as `pendingEffortScore`).
    private func captureClassRecapSnapshot(_ payload: ClassRecapPayload, _ state: State) {
        @Dependency(\.date.now) var now
        @Shared(.pendingClassRecap) var pendingClassRecap
        let gymName = state.joinLiveClass?.scannedQRPayload?.gymName ?? ""
        let classPoints = state.joinLiveClass?.currentEffortPoints ?? 0
        // An un-consumed prior snapshot means the previous class's `.workoutSaved`
        // never arrived — log before overwriting so a lost link is traceable.
        if let stale = pendingClassRecap {
            Logger.session.notice("pendingClassRecap overwritten before consume (class \(stale.classSessionId.uuidString.prefix(8)))")
        }
        $pendingClassRecap.withLock {
            $0 = PendingClassRecap(
                classSessionId: payload.classSessionId,
                gymName: gymName,
                place: payload.place,
                participantCount: payload.participantCount,
                classPoints: classPoints,
                latitude: payload.latitude,
                longitude: payload.longitude,
                captureDatetime: now
            )
        }
    }
}
