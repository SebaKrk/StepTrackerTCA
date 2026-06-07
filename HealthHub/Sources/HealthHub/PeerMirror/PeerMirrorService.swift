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
/// **samples** — pozostaje stored single-stream. iPad subscriber jest jeden (GymRoomView),
/// re-mount na iPadzie jest rzadki. Multicast TODO gdy iPad app będzie multi-room.
@MainActor
public final class PeerMirrorService {

    // MARK: - Sessions

    private var hostSession: PeerMirrorBLEHostSession?
    private var peerSession: PeerMirrorBLEPeerSession?

    // MARK: - peerEvents (multicast — N subscribers)

    private var peerEventContinuations: [UUID: AsyncStream<PeerEvent>.Continuation] = [:]

    // MARK: - samples (stored single stream — TODO multicast w przyszłości)

    private let samplesStreamSource: AsyncStream<HRSamplePayload>
    private let samplesContinuation: AsyncStream<HRSamplePayload>.Continuation

    public init() {
        let (sStream, sCont) = AsyncStream<HRSamplePayload>.makeStream()
        self.samplesStreamSource = sStream
        self.samplesContinuation = sCont
    }

    // MARK: - Host (iPad)

    public func startAdvertising(displayName: String) {
        stopAdvertising()
        let sampleContinuation = samplesContinuation
        hostSession = PeerMirrorBLEHostSession(
            displayName: displayName,
            onPeerEvent: { [weak self] event in
                Task { @MainActor in
                    self?.broadcastPeerEvent(event)
                }
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

    // MARK: - Streams (accessory)

    public func samplesStream() -> AsyncStream<HRSamplePayload> {
        samplesStreamSource
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

    private func broadcastPeerEvent(_ event: PeerEvent) {
        for continuation in peerEventContinuations.values {
            continuation.yield(event)
        }
    }
}
