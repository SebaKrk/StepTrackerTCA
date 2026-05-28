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
/// **Streams**: tworzone **eagerly w `init()`** przez `AsyncStream.makeStream()` —
/// continuation jest zawsze set od pierwszej chwili istnienia service'a. To eliminuje
/// race condition gdzie `startBrowsing/startAdvertising` captureowało jeszcze
/// nieustawioną continuation (gdy subscriber nie zdążył wywołać `peerEventsStream()`).
@MainActor
public final class PeerMirrorService {

    // MARK: - Sessions

    private var hostSession: PeerMirrorBLEHostSession?
    private var peerSession: PeerMirrorBLEPeerSession?

    // MARK: - Streams (eager init — never nil)

    private let peerEventsStreamSource: AsyncStream<PeerEvent>
    private let peerEventsContinuation: AsyncStream<PeerEvent>.Continuation

    private let samplesStreamSource: AsyncStream<HRSamplePayload>
    private let samplesContinuation: AsyncStream<HRSamplePayload>.Continuation

    public init() {
        let (eStream, eCont) = AsyncStream<PeerEvent>.makeStream()
        self.peerEventsStreamSource = eStream
        self.peerEventsContinuation = eCont

        let (sStream, sCont) = AsyncStream<HRSamplePayload>.makeStream()
        self.samplesStreamSource = sStream
        self.samplesContinuation = sCont
    }

    // MARK: - Host (iPad)

    public func startAdvertising(displayName: String) {
        stopAdvertising()
        let eventContinuation = peerEventsContinuation
        let sampleContinuation = samplesContinuation
        hostSession = PeerMirrorBLEHostSession(
            displayName: displayName,
            onPeerEvent: { event in
                eventContinuation.yield(event)
            },
            onSample: { payload in
                sampleContinuation.yield(payload)
            }
        )
    }

    public func stopAdvertising() {
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
        let eventContinuation = peerEventsContinuation
        peerSession = PeerMirrorBLEPeerSession(
            onPeerEvent: { event in
                eventContinuation.yield(event)
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

    // MARK: - Streams (accessory)

    public func samplesStream() -> AsyncStream<HRSamplePayload> {
        samplesStreamSource
    }

    public func peerEventsStream() -> AsyncStream<PeerEvent> {
        peerEventsStreamSource
    }
}
