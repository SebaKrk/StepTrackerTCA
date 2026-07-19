//
//  PeerMirrorService.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 23/05/2026.
//

import Foundation
import SharedModels

/// Orchestrator nad Bluetooth Low Energy transportem Gym Room PoC.
///
/// Cienka warstwa na main actor, trzymająca aktualny `PeerMirrorBLEHostSession?` /
/// `PeerMirrorBLEPeerSession?` i eksponująca dwa stream'y (samples + peer events)
/// skonsumowane przez warstwę The Composable Architecture (TCA).
///
/// **Lifecycle**: `start*` tworzy świeżą session (`CBPeripheralManager` / `CBCentralManager`),
/// `stop*` ją drop'uje. Recreation per call gwarantuje czysty BLE state przy każdym join.
///
/// **peerEvents — multicast** (IOS-00094-I): każdy subscriber dostaje świeży
/// `AsyncStream<PeerEvent>` zarejestrowany w `peerEventContinuations`. `AsyncStream` z natury
/// obsługuje tylko jednego iteratora; bez multicast'u drugi `for await` na stored stream
/// nic nie dostawał — bug ujawniał się przy view re-mount (np. iPhone-standalone + Gym Room).
/// Cleanup automatyczny przez `onTermination` gdy TCA cancel'uje effect.
///
/// **samples — multicast** (ten sam wzorzec): każdy `samplesStream()` call rejestruje swój
/// continuation w `samplesContinuations`. Bez multicast'u widok Gym Room po SwiftUI re-mount
/// (memory pressure, scene phase change) gubił próbki HR — dwa `for await` na single stored
/// stream konkurowały o elementy (race). Cleanup automatyczny przez `onTermination`.
@MainActor
public final class PeerMirrorService {

    // MARK: - Sessions

    /// Active iPad host session — tworzy się w `startAdvertising`, drop'owany w `stopAdvertising`.
    /// `nil` = advertising stopped (idle state).
    private var hostSession: PeerMirrorBLEHostSession?

    /// Active iPhone peer session — tworzy się w `startBrowsing`, drop'owany w `stopBrowsing`.
    /// `nil` = scanning stopped (idle state).
    private var peerSession: PeerMirrorBLEPeerSession?

    // MARK: - Multicast continuations

    /// Registry multicast continuations dla peer events — każdy `peerEventsStream()` call rejestruje nowy.
    /// Broadcast na `.connected` / `.suspended` / `.reconnected` / `.disconnected`. Cleanup automatyczny przez `onTermination`.
    private var peerEventContinuations: [UUID: AsyncStream<PeerEvent>.Continuation] = [:]

    /// Registry multicast continuations dla HR samples — każdy `samplesStream()` call rejestruje nowy.
    /// Broadcast na każdą próbkę z `PeerMirrorBLEHostSession.onSample`. Cleanup automatyczny przez `onTermination`.
    private var samplesContinuations: [UUID: AsyncStream<HRSamplePayload>.Continuation] = [:]

    // MARK: - Grace period buffer

    /// Tasks pending dla peerów w grace period (po `.suspended`). Key = `deviceID`.
    /// Po 10s timeout → emit `.disconnected`. Jeśli peer wraca z tym samym `deviceID`
    /// przed timeout → cancel task + emit `.reconnected` (zamiast `.connected`).
    /// Przy `stopAdvertising` cancel'ujemy wszystkie + emit `.disconnected` żeby reducer cleanup.
    private var disconnectingPeers: [UUID: Task<Void, Never>] = [:]

    /// Czas trwania grace window przed finalnym `.disconnected`. 5 minut pokrywa
    /// typowe CrossFit-box scenariusze z większym zapasem: toaleta, woda, dłuższy
    /// break, słaby zasięg BLE między strefami sali. Dłuższy okres nie kosztuje CPU
    /// (Task.sleep suspenduje task bez polling) ale powodowałby że faktyczne odejście
    /// (kontuzja, hipoglikemia) zostawia stale `.reconnecting` kafelek bez jasnego
    /// sygnału dla trenera. Krótszy (2 min) gubił peerów przy normalnym reconnect.
    private let gracePeriodSeconds: Duration = .seconds(300)

    public init() {}

    // MARK: - Host (iPad)

    public func startAdvertising(displayName: String, sessionToken: UUID) {
        stopAdvertising()
        hostSession = PeerMirrorBLEHostSession(
            displayName: displayName,
            sessionToken: sessionToken,
            onPeerEvent: { [weak self] event in
                Task { @MainActor in
                    self?.broadcastPeerEvent(event)
                }
            },
            onSample: { [weak self] payload in
                Task { @MainActor in
                    self?.broadcastSample(payload)
                }
            }
        )
    }

    public func stopAdvertising() {
        // Cancel wszystkie pending grace timers + emit `.disconnected` dla suspended peerów.
        // Bez tego: timery wciąż lecą po END Class → memory leak, plus late-emit `.disconnected`
        // gdy host już nie aktywny. Plus reducer mógłby pokazywać stale `.reconnecting` kafelki.
        for (deviceID, task) in disconnectingPeers {
            task.cancel()
            for continuation in peerEventContinuations.values {
                continuation.yield(.disconnected(deviceID: deviceID))
            }
        }
        disconnectingPeers.removeAll()

        hostSession?.stop()
        hostSession = nil
    }

    // MARK: - Peer (iPhone)

    /// `displayName` ignorowane w BLE — central nie advertise'uje. Nick przekazywany
    /// per-payload przez `HRSamplePayload.nick` (ustawiany w reducerze `JoinLiveClassFeature`).
    /// Parameter zachowany dla API-compat z istniejącym `PeerMirrorClient`.
    public func startBrowsing(displayName: String) {
        _ = displayName
        stopBrowsing()
        peerSession = PeerMirrorBLEPeerSession(
            onPeerEvent: { [weak self] event in
                Task { @MainActor in
                    self?.broadcastPeerEvent(event)
                }
            }
        )
    }

    public func stopBrowsing() {
        peerSession?.stop()
        peerSession = nil
    }

    public func send(_ payload: HRSamplePayload) {
        peerSession?.send(payload)
    }

    /// Host→peer: per-device recap na koniec zajęć. Deleguje do host session (no-op gdy
    /// nie jesteśmy hostem lub peer nie ma znanego central).
    public func sendRecap(_ payload: ClassRecapPayload, toDeviceID deviceID: UUID) {
        hostSession?.sendRecap(payload, toDeviceID: deviceID)
    }

    // MARK: - Streams (accessory)

    public func samplesStream() -> AsyncStream<HRSamplePayload> {
        let id = UUID()
        let (stream, continuation) = AsyncStream.makeStream(of: HRSamplePayload.self)
        continuation.onTermination = { [weak self] _ in
            Task { @MainActor in
                self?.samplesContinuations.removeValue(forKey: id)
            }
        }
        samplesContinuations[id] = continuation
        return stream
    }

    public func peerEventsStream() -> AsyncStream<PeerEvent> {
        let id = UUID()
        let (stream, continuation) = AsyncStream.makeStream(of: PeerEvent.self)
        continuation.onTermination = { [weak self] _ in
            Task { @MainActor in
                self?.peerEventContinuations.removeValue(forKey: id)
            }
        }
        peerEventContinuations[id] = continuation
        return stream
    }

    // MARK: - Private

    /// Orchestrates peer events z buforowaniem grace period:
    /// - `.connected` z deviceID który ma pending grace timer → cancel timer + emit `.reconnected`
    /// - `.suspended` → forward + start 10s timer (po timeout emit `.disconnected`)
    /// - `.disconnected` / `.reconnected` → forward direct (plus cleanup pending timer dla `.disconnected`)
    private func broadcastPeerEvent(_ event: PeerEvent) {
        switch event {
        case let .connected(deviceID, nick):
            if let pendingTimer = disconnectingPeers.removeValue(forKey: deviceID) {
                // Peer wraca w grace window — cancel timer i emit `.reconnected` zamiast `.connected`.
                pendingTimer.cancel()
                broadcast(.reconnected(deviceID: deviceID, nick: nick))
            } else {
                broadcast(event)
            }

        case let .suspended(deviceID, _):
            broadcast(event)
            startGraceTimer(deviceID: deviceID)

        case let .disconnected(deviceID):
            // Defensive cleanup — jeśli grace timer wciąż leci (rzadkie, np. host stop()
            // emit .disconnected zanim timer odpalił), anuluj go żeby nie emit duplikatu.
            disconnectingPeers.removeValue(forKey: deviceID)?.cancel()
            broadcast(event)

        case .reconnected:
            // Reconnected event nigdy nie przychodzi z `onPeerEvent` callback — emit'ujemy go
            // tylko wewnętrznie w branchu `.connected`. Defensive: forward na wszelki wypadek.
            broadcast(event)

        case .classEnded:
            // Host (iPad) zakończył klasę — broadcast do consumer'ów (peer-side reducer
            // robi reset state). Plus cancel wszystkie pending grace timers (klasa skończona
            // ↔ wszyscy peerzy są lost, brak sensownego reconnect).
            for (_, task) in disconnectingPeers { task.cancel() }
            disconnectingPeers.removeAll()
            broadcast(event)

        case .recapReceived:
            // Peer-side: host przysłał wynik zajęć — forward do consumer'a (JoinLiveClass
            // parkuje pending recap). To nie zdarzenie lifecycle połączenia, więc bez
            // grace-timer logiki.
            broadcast(event)
        }
    }

    private func broadcast(_ event: PeerEvent) {
        for continuation in peerEventContinuations.values {
            continuation.yield(event)
        }
    }

    /// Startuje 10s timer po `.suspended` — po timeout emit `.disconnected` i cleanup.
    /// Cancel'owany w branchu `.connected` (gdy peer wraca w grace window).
    private func startGraceTimer(deviceID: UUID) {
        // Cancel istniejący timer (rzadkie, ale defensive — np. peer suspend→suspend race).
        disconnectingPeers[deviceID]?.cancel()

        disconnectingPeers[deviceID] = Task { [weak self, gracePeriodSeconds] in
            do {
                try await Task.sleep(for: gracePeriodSeconds)
            } catch {
                return  // Cancelled przez reconnect lub stopAdvertising
            }
            await self?.finalizeDisconnection(deviceID: deviceID)
        }
    }

    /// Wywoływane gdy grace timer wygasł — peer faktycznie zniknął, emit `.disconnected`.
    private func finalizeDisconnection(deviceID: UUID) {
        disconnectingPeers.removeValue(forKey: deviceID)
        broadcast(.disconnected(deviceID: deviceID))
    }

    private func broadcastSample(_ payload: HRSamplePayload) {
        for continuation in samplesContinuations.values {
            continuation.yield(payload)
        }
    }
}
