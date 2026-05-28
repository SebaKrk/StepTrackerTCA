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

    public var startAdvertising: @Sendable (_ displayName: String) async -> Void
    public var stopAdvertising: @Sendable () async -> Void

    public var startBrowsing: @Sendable (_ displayName: String) async -> Void
    public var stopBrowsing: @Sendable () async -> Void

    public var send: @Sendable (_ payload: HRSamplePayload) async -> Void

    public var samplesStream: @Sendable () async -> AsyncStream<HRSamplePayload>
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
