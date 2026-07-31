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
    @Dependency(\.bluetoothClient) var bluetoothClient
    @Dependency(\.continuousClock) var clock

    /// Okno reconnectu po stronie peera — odpowiada host-side grace
    /// (`PeerMirrorService.gracePeriodSeconds`). Po nim peer wychodzi ze `.searching`
    /// do `.connectionLost`, bo host i tak usunął kafelek po tym czasie.
    static let searchTimeout: Duration = .seconds(300)

    /// Timer odpalany przy każdym wejściu w `.searching`. `cancelInFlight: true`
    /// restartuje go przy ponownym suspendzie / ponownym scanie. Anulowany w
    /// `.peerConnected` (wróciliśmy) oraz przy leave / class end.
    private var startSearchTimeout: Effect<Action> {
        .run { send in
            try await clock.sleep(for: Self.searchTimeout)
            await send(.searchTimeoutElapsed)
        }
        .cancellable(id: JoinLiveClassCancelID.searchTimeout, cancelInFlight: true)
    }

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
                    .send(.startObservingSensorConnection),
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
                // żeby host od razu usunął tile (skip 5 min grace period). `send` dla goodbye
                // czeka na ACK hosta (max 1 s), więc teardown nie ściga się z dostarczeniem.
                let goodbyeDeviceID = state.deviceID
                let goodbyeToken = state.scannedQRPayload?.token
                let goodbyeNick = state.nick
                let goodbyeMaxHR = state.maxHeartRate
                let goodbyeEffortPoints = state.currentEffortPoints

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
                                endOfClass: true,
                                effortPoints: goodbyeEffortPoints
                            )
                            Logger.gymRoom.info("[Peer] Sending goodbye (leaveTapped) — endOfClass=true")
                            // Suspends until the host ACKs the goodbye (max 1 s) —
                            // safe to tear the link down right after.
                            await peerMirrorClient.send(goodbye)
                        }
                        await peerMirrorClient.stopBrowsing()
                    },
                    .cancel(id: JoinLiveClassCancelID.hrStream),
                    .cancel(id: JoinLiveClassCancelID.peerEvents),
                    .cancel(id: JoinLiveClassCancelID.searchTimeout),
                    .cancel(id: JoinLiveClassCancelID.sensorConnection),
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
                    startSearchTimeout,
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
                        case .classEnded:
                            // Host (iPad) explicit END Class — natychmiast reset state
                            // (NIE przechodzić do .searching, bo iPad nie wróci).
                            await send(.classEndedReceived)
                        case let .recapReceived(payload):
                            await send(.recapReceived(payload))
                        }
                    }
                }
                .cancellable(id: JoinLiveClassCancelID.peerEvents)

            case .startObservingSensorConnection:
                // Local BLE-layer disconnect reason for the held HR strap. Independent
                // of `isSensorStale` (a 15 s timeout the parent bridges): this carries
                // WHY the strap dropped. Silent on watchPrimary (no BLE strap held).
                return .run { send in
                    for await reason in await bluetoothClient.hrSensorConnectionEvents() {
                        await send(.sensorDisconnectReasonChanged(reason))
                    }
                }
                .cancellable(id: JoinLiveClassCancelID.sensorConnection)

            case let .sensorDisconnectReasonChanged(reason):
                state.lastDisconnectReason = reason
                return .none

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
                return .merge(
                    .cancel(id: JoinLiveClassCancelID.searchTimeout),
                    // Tell the parent we're in the class so it can snapshot the effort
                    // origin. Fires on reconnect too — the parent guards against reset.
                    .send(.delegate(.joinedClass)),
                    .run { [sessionClient, peerMirrorClient, initialPayload] send in
                    await peerMirrorClient.send(initialPayload)
                    // Payload construction happens in the reducer (.workoutMetricsReceived)
                    // so each send reads CURRENT state — notably `currentEffortPoints`
                    // synced by the parent from the LiveSession counter.
                    for await metrics in await sessionClient.workoutMetricsStream() {
                        Logger.gymRoom.debug("[Peer] metrics received HR=\(Int(metrics.heartRate))")
                        guard metrics.heartRate > 0 else { continue }
                        await send(.workoutMetricsReceived(metrics))
                    }
                    // Stream zakończył się naturalnie (workout end z HK — np. user kończy
                    // trening na Watchu lub iPhone-side workout session ends). Goodbye
                    // wysyła handler `.workoutEnded` (buduje payload ze state — z punktami).
                    Logger.gymRoom.info("[Peer] workoutMetricsStream ended — emit workoutEnded")
                    // Subtask H2: emit `.workoutEnded` żeby reducer reset state — bez tego
                    // peer-side wciąż w phase .connected, toolbar icon nie znika aż do tap Leave.
                    await send(.workoutEnded)
                }
                    .cancellable(id: JoinLiveClassCancelID.hrStream)
                )

            case let .workoutMetricsReceived(metrics):
                // Defensive: stream cancellation races with phase changes — never
                // broadcast after leave/disconnect, and never without a token.
                guard state.phase == .connected,
                      let sessionToken = state.scannedQRPayload?.token else { return .none }
                let payload = HRSamplePayload(
                    deviceID: state.deviceID,
                    sessionToken: sessionToken,
                    nick: state.nick,
                    bpm: Int(metrics.heartRate),
                    maxHR: state.maxHeartRate,
                    activeEnergy: metrics.activeEnergy,
                    effortPoints: state.currentEffortPoints,
                    isSensorStale: state.isSensorStale,
                    disconnectReason: state.lastDisconnectReason,
                    watchLinkLost: state.watchLinkLost
                )
                Logger.gymRoom.debug("[Peer] forwarding to iPad: \(Int(metrics.heartRate)) bpm, \(metrics.activeEnergy) kcal, \(payload.effortPoints ?? 0) pts")
                return .run { [peerMirrorClient] _ in
                    await peerMirrorClient.send(payload)
                }

            case let .recapReceived(payload):
                // Host przysłał wynik zajęć — oddaj parentowi (SessionFeature parkuje
                // pending class recap, dokładając lokalny gymName + classPoints).
                return .send(.delegate(.recapReceived(payload)))

            case .peerDisconnected:
                Logger.gymRoom.info("[Peer] disconnected — searching + start 5min reconnect timeout")
                state.phase = .searching
                return .merge(
                    .cancel(id: JoinLiveClassCancelID.hrStream),
                    startSearchTimeout
                )

            case .searchTimeoutElapsed:
                // Race guard: jeśli zdążyliśmy wrócić (.peerConnected) timer jest cancel'owany,
                // ale action mógł być już in-flight — guard chroni przed fałszywym connectionLost.
                guard state.phase == .searching else { return .none }
                Logger.gymRoom.info("[Peer] reconnect timeout (5 min) — connection lost, stopping browse")
                state.phase = .connectionLost
                state.scannedQRPayload = nil
                return .run { _ in await peerMirrorClient.stopBrowsing() }

            case .classEndedReceived, .workoutEnded:
                // Klasa się zakończyła z dowolnej strony:
                // - .classEndedReceived → host (iPad) tap End Class → BLE notify broadcast
                // - .workoutEnded → peer-side workoutMetricsStream zakończył (Watch/HK end)
                // Identical outcome: pełen reset state + delegate.didLeave (toolbar icon znika).
                //
                // Idempotency guard — race possible gdy Watch end i iPad END odpalają się
                // równolegle (oba prowadzą do reset). Drugi action już .idle — skip żeby
                // uniknąć redundant stopBrowsing/didLeave (BLE stack może log warning,
                // parent może log "already left").
                guard state.phase != .idle else {
                    Logger.gymRoom.info("[Peer] Already .idle — skip duplicate reset")
                    return .none
                }
                // Goodbye only on natural workout end — built from state BEFORE the
                // reset so it carries the final effort points total (the tile and the
                // class-end table show the athlete's definitive score). On
                // `.classEndedReceived` the host ended the class — nothing to notify.
                let goodbye: HRSamplePayload? = {
                    guard case .workoutEnded = action,
                          let token = state.scannedQRPayload?.token else { return nil }
                    return HRSamplePayload(
                        deviceID: state.deviceID,
                        sessionToken: token,
                        nick: state.nick,
                        bpm: 0,
                        maxHR: state.maxHeartRate,
                        endOfClass: true,
                        effortPoints: state.currentEffortPoints
                    )
                }()
                Logger.gymRoom.info("[Peer] Session ended — auto-reset state")
                state.phase = .idle
                state.scannedQRPayload = nil
                state.isShowingScanner = false
                return .merge(
                    .cancel(id: JoinLiveClassCancelID.hrStream),
                    .cancel(id: JoinLiveClassCancelID.peerEvents),
                    .cancel(id: JoinLiveClassCancelID.searchTimeout),
                    .cancel(id: JoinLiveClassCancelID.sensorConnection),
                    .run { [peerMirrorClient] _ in
                        if let goodbye {
                            Logger.gymRoom.info("[Peer] Sending goodbye (workoutEnded) — endOfClass=true, \(goodbye.effortPoints ?? 0) pts")
                            // Suspends until the host ACKs the goodbye (max 1 s) —
                            // safe to tear the link down right after.
                            await peerMirrorClient.send(goodbye)
                        }
                        await peerMirrorClient.stopBrowsing()
                    },
                    .send(.delegate(.didLeave))
                )

                // MARK: - Delegate

            case .delegate:
                return .none
            }
        }
    }
}
