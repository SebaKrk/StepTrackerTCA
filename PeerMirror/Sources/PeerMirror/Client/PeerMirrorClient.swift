//
//  PeerMirrorClient.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 23/05/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

/// The Composable Architecture (TCA) dependency boundary nad `PeerMirrorService`.
///
/// **Pattern**: ten sam co `WidgetCenterClient` — `struct: Sendable` z closure properties
/// (bez `@DependencyClient` macro żeby uniknąć Data parameter pitfall).
public struct PeerMirrorClient: Sendable {

    /// Starts advertising iPad as Gym Room host — publikuje GATT service, czeka na iPhone connections.
    /// Parametr `displayName` widoczny w Discovery Info characteristic.
    public var startAdvertising: @Sendable (_ displayName: String) async -> Void

    /// Stops advertising — zamyka BLE peripheral, emituje `.disconnected` dla aktywnych centralów.
    public var stopAdvertising: @Sendable () async -> Void

    /// Starts scanning iPhone — szuka BLE iPad advertisementów, łączy się i subskrybuje HR stream.
    /// Parametr `displayName` ustawiany w reducerze (z UserProfile), przesyłany per-payload nie w BLE.
    public var startBrowsing: @Sendable (_ displayName: String) async -> Void

    /// Stops scanning iPhone — zamyka BLE central, emituje `.disconnected`.
    public var stopBrowsing: @Sendable () async -> Void

    /// Sends HR sample payload do iPada — `peerSession?.send(_:)`, brak-op jeśli nie connected.
    public var send: @Sendable (_ payload: HRSamplePayload) async -> Void

    /// Returns fresh multicast `AsyncStream<HRSamplePayload>` — każdy subscriber dostaje swój stream.
    /// Cleanup przez `onTermination` gdy effect anuluje TCA (view re-mount, stop, itp).
    public var samplesStream: @Sendable () async -> AsyncStream<HRSamplePayload>

    /// Returns fresh multicast `AsyncStream<PeerEvent>` — każdy subscriber dostaje swój stream.
    /// Emituje `.connected(deviceID:nick:)` i `.disconnected(deviceID:)` dla host + peer roles.
    /// Cleanup przez `onTermination` gdy effect anuluje TCA (zmiana route, stop browsing, itp).
    public var peerEventsStream: @Sendable () async -> AsyncStream<PeerEvent>

    public init(
        startAdvertising: @escaping @Sendable (_ displayName: String) async -> Void,
        stopAdvertising: @escaping @Sendable () async -> Void,
        startBrowsing: @escaping @Sendable (_ displayName: String) async -> Void,
        stopBrowsing: @escaping @Sendable () async -> Void,
        send: @escaping @Sendable (_ payload: HRSamplePayload) async -> Void,
        samplesStream: @escaping @Sendable () async -> AsyncStream<HRSamplePayload>,
        peerEventsStream: @escaping @Sendable () async -> AsyncStream<PeerEvent>
    ) {
        self.startAdvertising = startAdvertising
        self.stopAdvertising = stopAdvertising
        self.startBrowsing = startBrowsing
        self.stopBrowsing = stopBrowsing
        self.send = send
        self.samplesStream = samplesStream
        self.peerEventsStream = peerEventsStream
    }
}

// MARK: - DependencyKey

extension PeerMirrorClient: DependencyKey {

    public static let liveValue: PeerMirrorClient = {
        // Singleton service — jedna instancja per proces, owns aktualny
        // PeerMirrorHostSession / PeerMirrorPeerSession.
        let service = PeerMirrorService()

        return PeerMirrorClient(
            startAdvertising: { displayName in
                await service.startAdvertising(displayName: displayName)
            },
            stopAdvertising: {
                await service.stopAdvertising()
            },
            startBrowsing: { displayName in
                await service.startBrowsing(displayName: displayName)
            },
            stopBrowsing: {
                await service.stopBrowsing()
            },
            send: { payload in
                await service.send(payload)
            },
            samplesStream: {
                await service.samplesStream()
            },
            peerEventsStream: {
                await service.peerEventsStream()
            }
        )
    }()

    public static let testValue: PeerMirrorClient = PeerMirrorClient(
        startAdvertising: unimplemented("PeerMirrorClient.startAdvertising"),
        stopAdvertising: unimplemented("PeerMirrorClient.stopAdvertising"),
        startBrowsing: unimplemented("PeerMirrorClient.startBrowsing"),
        stopBrowsing: unimplemented("PeerMirrorClient.stopBrowsing"),
        send: unimplemented("PeerMirrorClient.send"),
        samplesStream: unimplemented("PeerMirrorClient.samplesStream", placeholder: AsyncStream { _ in }),
        peerEventsStream: unimplemented("PeerMirrorClient.peerEventsStream", placeholder: AsyncStream { _ in })
    )
}

// MARK: - DependencyValues

public extension DependencyValues {
    var peerMirrorClient: PeerMirrorClient {
        get { self[PeerMirrorClient.self] }
        set { self[PeerMirrorClient.self] = newValue }
    }
}
