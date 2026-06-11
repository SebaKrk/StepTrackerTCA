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
    /// Broadcast na `.connected` / `.disconnected`. Cleanup automatyczny przez `onTermination`.
    private var peerEventContinuations: [UUID: AsyncStream<PeerEvent>.Continuation] = [:]

    /// Registry multicast continuations dla HR samples — każdy `samplesStream()` call rejestruje nowy.
    /// Broadcast na każdą próbkę z `PeerMirrorBLEHostSession.onSample`. Cleanup automatyczny przez `onTermination`.
    private var samplesContinuations: [UUID: AsyncStream<HRSamplePayload>.Continuation] = [:]

    public init() {}

    // MARK: - Host (iPad)

    public func startAdvertising(displayName: String) {
        stopAdvertising()
        hostSession = PeerMirrorBLEHostSession(
            displayName: displayName,
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

    private func broadcastPeerEvent(_ event: PeerEvent) {
        for continuation in peerEventContinuations.values {
            continuation.yield(event)
        }
    }

    private func broadcastSample(_ payload: HRSamplePayload) {
        for continuation in samplesContinuations.values {
            continuation.yield(payload)
        }
    }
}
