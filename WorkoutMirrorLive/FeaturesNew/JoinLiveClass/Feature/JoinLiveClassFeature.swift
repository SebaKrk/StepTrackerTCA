//
//  JoinLiveClassFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 23/05/2026.
//

import ComposableArchitecture
import Foundation
import PeerMirror
import OSLog
import SharedModels

/// Reducer iPhone'a — dołącza do hosta (iPad) w sieci lokalnej i broadcastuje real HR
/// przez `sessionClient.workoutMetricsStream()` (routuje per WorkoutMode:
/// watchPrimary → trainingManager (HR z Watcha via HK mirroring),
/// iPhoneStandalone → iPhoneWorkoutSession.metrics (HR z BLE sensora)).
///
/// **Wymaganie**: aktywna workout session — Watch lub iPhone+BLE.
@Reducer
struct JoinLiveClassFeature {

    // MARK: - Dependencies

    @Dependency(\.peerMirrorClient) var peerMirrorClient
    @Dependency(\.sessionClient) var sessionClient
    @Dependency(\.userProfileClient) var userProfileClient

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {

                // MARK: - View Actions

            case .view(.viewDidAppear):
                // Subskrybujemy stream PRZED `joinTapped` — eager subscription
                // zapobiega race condition z `startBrowsing` capturującym
                // jeszcze niezainicjalizowaną continuation.
                // Plus: fetch user profile żeby ustawić display name (nickname → name → fallback).
                return .merge(
                    .send(.startObservingPeerEvents),
                    .run { [userProfileClient] send in
                        let profile = try? await userProfileClient.fetch()
                        await send(.userProfileLoaded(profile))
                    }
                )

            case .view(.joinTapped):
                // Tap Join = "chcę dołączyć" — otwieramy scanner, ale jeszcze NIE startujemy
                // BLE handshake (potrzebny sessionToken z scannedQRPayload). Sheet pozostaje
                // otwarty, scanner pojawia się jako fullScreenCover.
                state.isShowingScanner = true
                return .none

            case .view(.leaveTapped):
                // "Zakończ klasę" — broadcast stop + delegate.didLeave (parent kasuje state).
                // Reset scannedQRPayload + isShowingScanner — wymusza pełen scan flow ponownie.
                //
                // Graceful disconnect: PRZED stopBrowsing wyślij goodbye payload z `endOfClass=true`,
                // żeby host od razu usunął tile (skip 2min grace period). Krótki delay (300ms) daje
                // BLE write'owi czas żeby trafił do iPada zanim peripheral się rozłączy.
                let goodbyeDeviceID = state.deviceID
                let goodbyeToken = state.scannedQRPayload?.token
                let goodbyeNick = state.nick
                let goodbyeMaxHR = state.maxHeartRate

                state.phase = .idle
                state.scannedQRPayload = nil
                state.isShowingScanner = false
                return .merge(
                    .run { [peerMirrorClient] _ in
                        if let token = goodbyeToken {
                            let goodbye = HRSamplePayload(
                                deviceID: goodbyeDeviceID,
                                sessionToken: token,
                                nick: goodbyeNick,
                                bpm: 0,
                                maxHR: goodbyeMaxHR,
                                endOfClass: true
                            )
                            Logger.gymRoom.info("[Peer] Sending goodbye (leaveTapped) — endOfClass=true")
                            await peerMirrorClient.send(goodbye)
                            try? await Task.sleep(for: .milliseconds(300))
                        }
                        await peerMirrorClient.stopBrowsing()
                    },
                    .cancel(id: JoinLiveClassCancelID.hrStream),
                    .cancel(id: JoinLiveClassCancelID.peerEvents),
                    .send(.delegate(.didLeave))
                )

            case .view(.closeTapped):
                // Sheet schowany (X / swipe-down) — broadcast TRWA, state żyje, ikona toolbar
                // pozostaje "connected". User otworzy sheet znowu klikając ikonę.
                return .send(.delegate(.didDismiss))

            case let .view(.qrScanned(jsonString)):
                // QR scanner odebrał payload — decode JSON. Malformed = log + zamknij scanner
                // (zostaje w state .idle, user widzi Join button żeby spróbować ponownie).
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                guard let data = jsonString.data(using: .utf8),
                      let payload = try? decoder.decode(QRSessionPayload.self, from: data) else {
                    Logger.gymRoom.error("[QR] Failed to decode scanned payload (malformed JSON)")
                    state.isShowingScanner = false
                    return .none
                }
                Logger.gymRoom.info("[QR] Scanned payload — gym=\(payload.gymName) token=\(payload.token.uuidString.prefix(8))")
                // Sukces: zamknij scanner, set scannedQRPayload, start BLE handshake.
                // Sheet parent też się zamyka — broadcast trwa w tle, user widzi toolbar icon.
                state.scannedQRPayload = payload
                state.isShowingScanner = false
                state.phase = .searching
                let nick = state.nick
                return .merge(
                    .run { _ in await peerMirrorClient.startBrowsing(nick) },
                    .send(.delegate(.didDismiss))
                )

            case .view(.scannerDismissed):
                // User swipe-down scanner bez scanowania — wraca do idle z Join button.
                state.isShowingScanner = false
                return .none

                // MARK: - Internal

            case let .userProfileLoaded(profile):
                // Fallback chain: nickname → name → keep current ("Athlete-XXX" z AppStorage).
                // Nigdy nie nadpisujemy `state.nick` pustym stringiem.
                if let profile {
                    Logger.gymRoom.info("[Profile] loaded: name='\(profile.name)' surname='\(profile.surname)' nickname='\(profile.nickname)'")
                } else {
                    Logger.gymRoom.info("[Profile] NIL — no UserProfile in database")
                }
                guard let profile else { return .none }
                if !profile.nickname.isEmpty {
                    Logger.gymRoom.info("[Profile] using nickname: '\(profile.nickname)'")
                    state.$nick.withLock { $0 = profile.nickname }
                } else if !profile.name.isEmpty {
                    Logger.gymRoom.info("[Profile] using name: '\(profile.name)'")
                    state.$nick.withLock { $0 = profile.name }
                } else {
                    let currentNick = state.nick
                    Logger.gymRoom.info("[Profile] both nickname and name empty — keeping default '\(currentNick)'")
                }
                return .none

            case .startObservingPeerEvents:
                return .run { send in
                    for await event in await peerMirrorClient.peerEventsStream() {
                        switch event {
                        case .connected, .reconnected:
                            // Z perspektywy peer'a (iPhone) reconnect i fresh connect są
                            // ekwiwalentne — oba znaczą "iPad available, start broadcasting HR".
                            await send(.peerConnected)
                        case .disconnected:
                            await send(.peerDisconnected)
                        case .suspended:
                            // Host-side grace period — peer-side ignoruje. Peer ma swój własny
                            // exponential backoff reconnect w PeerMirrorBLEPeerSession.
                            break
                        }
                    }
                }
                .cancellable(id: JoinLiveClassCancelID.peerEvents)

            case .peerConnected:
                Logger.gymRoom.info("[Peer] connected — starting workoutMetricsStream subscription")
                state.phase = .connected
                let nick = state.nick
                let deviceID = state.deviceID
                let maxHR = state.maxHeartRate
                // Token ze scanned QR — bez niego peer nie powinien tu wejść
                // (joinTapped wymusza scan first). Defensive log + skip dla scenariusza
                // gdyby parent feature wymusił joinTapped pomijając scan flow.
                guard let sessionToken = state.scannedQRPayload?.token else {
                    Logger.gymRoom.error("[Peer] No scannedQRPayload — cannot broadcast without token")
                    return .none
                }
                // Initial registration payload (bpm=0) — iPad creates tile immediately
                // even before HR sensor connects. Subsequent payloads update HR/kcal
                // when workoutMetricsStream yields values > 0.
                let initialPayload = HRSamplePayload(
                    deviceID: deviceID,
                    sessionToken: sessionToken,
                    nick: nick,
                    bpm: 0,
                    maxHR: maxHR,
                    activeEnergy: 0
                )
                Logger.gymRoom.info("[Peer] sending initial registration — nick=\(nick), bpm=0")
                return .run { [sessionClient, peerMirrorClient, initialPayload, deviceID, sessionToken, nick, maxHR] _ in
                    await peerMirrorClient.send(initialPayload)
                    for await metrics in await sessionClient.workoutMetricsStream() {
                        Logger.gymRoom.debug("[Peer] metrics received HR=\(Int(metrics.heartRate))")
                        guard metrics.heartRate > 0 else { continue }
                        let payload = HRSamplePayload(
                            deviceID: deviceID,
                            sessionToken: sessionToken,
                            nick: nick,
                            bpm: Int(metrics.heartRate),
                            maxHR: maxHR,
                            activeEnergy: metrics.activeEnergy
                        )
                        Logger.gymRoom.debug("[Peer] forwarding to iPad: \(Int(metrics.heartRate)) bpm, \(metrics.activeEnergy) kcal")
                        await peerMirrorClient.send(payload)
                    }
                    // Stream zakończył się naturalnie (workout end z HK — np. user kończy
                    // trening na Watchu lub iPhone-side workout session ends). Wyślij goodbye
                    // żeby iPad usunął tile od razu, bez 2min grace period.
                    Logger.gymRoom.info("[Peer] workoutMetricsStream ended — sending goodbye (endOfClass=true)")
                    let goodbye = HRSamplePayload(
                        deviceID: deviceID,
                        sessionToken: sessionToken,
                        nick: nick,
                        bpm: 0,
                        maxHR: maxHR,
                        endOfClass: true
                    )
                    await peerMirrorClient.send(goodbye)
                }
                .cancellable(id: JoinLiveClassCancelID.hrStream)

            case .peerDisconnected:
                Logger.gymRoom.info("[Peer] disconnected — cancelling HR stream, returning to searching")
                state.phase = .searching
                return .cancel(id: JoinLiveClassCancelID.hrStream)

                // MARK: - Delegate

            case .delegate:
                return .none
            }
        }
    }
}
