//
//  GymRoomFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 11/06/2026.
//


//
//  GymRoomFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 23/05/2026.
//

import ComposableArchitecture
import Foundation
import OSLog
import PeerMirror
import SharedModels

/// Reducer iPada dla Proof of Concept Gym Room.
///
/// Stan: `isLive` + lista `athletes`.
/// Side effects: subskrypcja dwóch streamów z `PeerMirrorClient` (peer events + samples)
/// oraz wywołanie `startAdvertising` / `stopAdvertising` przy `startTapped` / `endTapped`.
@Reducer
struct
GymRoomFeature {

    // MARK: - Dependencies

    @Dependency(\.peerMirrorClient) var peerMirrorClient

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {

                // MARK: - View Actions

            case .view(.viewDidAppear):
                Logger.gymRoom.info("🎬 GymRoomView appeared — starting observations")
                return .merge(
                    .send(.startObservingPeerEvents),
                    .send(.startObservingSamples)
                )

            case .view(.startTapped):
                Logger.gymRoom.info("▶️ Start tapped — advertising as 'Gym Room'")
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
                Logger.gymRoom.info("✅ Peer connected: \(nick)")
                guard state.athletes[id: nick] == nil else { return .none }
                state.athletes.append(AthleteTile(id: nick))
                return .none

            case let .peerDisconnected(nick):
                Logger.gymRoom.info("❌ Peer disconnected: \(nick)")
                state.athletes.remove(id: nick)
                return .none

            case let .sampleReceived(payload):
                guard var tile = state.athletes[id: payload.nick] else { return .none }
                tile.bpm = payload.bpm
                tile.maxHR = payload.maxHR
                tile.activeEnergy = payload.activeEnergy
                state.athletes[id: payload.nick] = tile
                Logger.gymRoom.debug("💓 Updated \(payload.nick): \(payload.bpm) bpm")
                return .none

            case .startObservingPeerEvents:
                Logger.gymRoom.info("📡 Starting peer events observation...")
                return .run { send in
                    for await event in await peerMirrorClient.peerEventsStream() {
                        switch event {
                        case let .connected(_, nick):
                            await send(.peerConnected(nick: nick))
                        case let .disconnected(peerID):
                            await send(.peerDisconnected(nick: peerID))
                        }
                    }
                }
                .cancellable(id: GymRoomCancelID.peerEvents)

            case .startObservingSamples:
                Logger.gymRoom.info("🔥 Starting samples observation...")
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
