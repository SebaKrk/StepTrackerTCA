//
//  GymRoomFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 23/05/2026.
//

import ComposableArchitecture
import Foundation
import HealthHub
import SharedModels

/// Reducer iPada dla Proof of Concept Gym Room.
///
/// Stan: `isLive` + lista `athletes`.
/// Side effects: subskrypcja dwóch streamów z `PeerMirrorClient` (peer events + samples)
/// oraz wywołanie `startAdvertising` / `stopAdvertising` przy `startTapped` / `endTapped`.
@Reducer
struct GymRoomFeature {

    // MARK: - Dependencies

    @Dependency(\.peerMirrorClient) var peerMirrorClient

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {

                // MARK: - View Actions

            case .view(.viewDidAppear):
                return .merge(
                    .send(.startObservingPeerEvents),
                    .send(.startObservingSamples)
                )

            case .view(.startTapped):
                state.isLive = true
                return .run { _ in
                    await peerMirrorClient.startAdvertising("Gym Room")
                }

            case .view(.endTapped):
                state.isLive = false
                state.athletes.removeAll()
                return .run { _ in
                    await peerMirrorClient.stopAdvertising()
                }

                // MARK: - Internal

            case let .peerConnected(nick):
                guard state.athletes[id: nick] == nil else { return .none }
                state.athletes.append(AthleteTile(id: nick))
                return .none

            case let .peerDisconnected(nick):
                state.athletes.remove(id: nick)
                return .none

            case let .sampleReceived(payload):
                guard var tile = state.athletes[id: payload.nick] else { return .none }
                tile.bpm = payload.bpm
                tile.maxHR = payload.maxHR
                tile.activeEnergy = payload.activeEnergy
                state.athletes[id: payload.nick] = tile
                return .none

            case .startObservingPeerEvents:
                return .run { send in
                    for await event in await peerMirrorClient.peerEventsStream() {
                        switch event {
                        case let .connected(_, nick):
                            await send(.peerConnected(nick: nick))
                        case let .disconnected(peerID):
                            // peerID == nick w naszym setupie (MCPeerID.displayName)
                            await send(.peerDisconnected(nick: peerID))
                        }
                    }
                }
                .cancellable(id: GymRoomCancelID.peerEvents)

            case .startObservingSamples:
                return .run { send in
                    for await sample in await peerMirrorClient.samplesStream() {
                        await send(.sampleReceived(sample))
                    }
                }
                .cancellable(id: GymRoomCancelID.samples)
            }
        }
    }
}
