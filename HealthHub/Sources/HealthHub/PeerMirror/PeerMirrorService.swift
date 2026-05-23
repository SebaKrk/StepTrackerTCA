//
//  PeerMirrorService.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 23/05/2026.
//

import Foundation
import SharedModels

/// Orchestrator nad MultipeerConnectivity dla Proof of Concept Gym Room.
///
/// Cienka warstwa na main actor, trzymająca aktualny `PeerMirrorHostSession?` /
/// `PeerMirrorPeerSession?` i eksponująca dwa stream'y (samples + peer events)
/// skonsumowane przez warstwę The Composable Architecture (TCA).
///
/// **Lifecycle**: `start*` tworzy świeżą session (`MCPeerID` + `MCSession` ad-hoc),
/// `stop*` ją drop'uje. Recreation per call gwarantuje czysty state przy każdym join.
///
/// **Streams**: tworzone **eagerly w `init()`** przez `AsyncStream.makeStream()` —
/// continuation jest zawsze set od pierwszej chwili istnienia service'a. To eliminuje
/// race condition gdzie `startBrowsing/startAdvertising` captureowało jeszcze
/// nieustawioną continuation (gdy subscriber nie zdążył wywołać `peerEventsStream()`).
@MainActor
public final class PeerMirrorService {

    /// Bonjour service type. ≤15 chars, lowercase + hyphens (RFC 6335). 7 chars.
    ///
    /// `nonisolated` bo `PeerMirrorService` jest `@MainActor` — bez tego modyfikatora
    /// `serviceType` dziedziczy isolation i nie da się czytać z non-isolated init'ów
    /// `PeerMirrorHostSession` / `PeerMirrorPeerSession`. Immutable String → safe.
    public nonisolated static let serviceType = "mfj-gym"

    // MARK: - Sessions

    private var hostSession: PeerMirrorHostSession?
    private var peerSession: PeerMirrorPeerSession?

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
        hostSession = PeerMirrorHostSession(
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

    public func startBrowsing(displayName: String) {
        stopBrowsing()
        let eventContinuation = peerEventsContinuation
        peerSession = PeerMirrorPeerSession(
            displayName: displayName,
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
