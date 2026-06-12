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
                Logger.gymRoom.info("▶️ Start tapped — advertising as '\(state.gymName)'")
                state.isLive = true
                let token = UUID()
                state.sessionToken = token    // fresh token per class — encoded w QR
                state.isQRVisible = true      // reset visibility on new class
                let gymName = state.gymName
                return .run { _ in
                    await peerMirrorClient.startAdvertising(gymName, token)
                }

            case .view(.endTapped):
                Logger.gymRoom.info("⏹️ End tapped — invalidating session token")
                state.isLive = false
                state.athletes.removeAll()
                state.sessionToken = nil      // invalidate — stale QR scans odrzucone (subtask C3)
                return .run { _ in
                    await peerMirrorClient.stopAdvertising()
                }

            case .view(.toggleQR):
                state.isQRVisible.toggle()
                return .none

                // MARK: - Internal

            case let .peerConnected(deviceID, nick):
                Logger.gymRoom.info("✅ Peer connected: \(nick) (deviceID: \(deviceID.uuidString.prefix(8)))")
                guard state.athletes[id: deviceID] == nil else { return .none }
                state.athletes.append(AthleteTile(id: deviceID, nick: nick))
                return .none

            case let .peerDisconnected(deviceID):
                Logger.gymRoom.info("❌ Peer disconnected: \(deviceID.uuidString.prefix(8))")
                state.athletes.remove(id: deviceID)
                return .none

            case let .sampleReceived(payload):
                guard var tile = state.athletes[id: payload.deviceID] else { return .none }
                tile.bpm = payload.bpm
                tile.maxHR = payload.maxHR
                tile.activeEnergy = payload.activeEnergy
                state.athletes[id: payload.deviceID] = tile
                Logger.gymRoom.debug("💓 Updated \(payload.nick): \(payload.bpm) bpm")
                return .none

            case .startObservingPeerEvents:
                Logger.gymRoom.info("📡 Starting peer events observation...")
                return .run { send in
                    for await event in await peerMirrorClient.peerEventsStream() {
                        switch event {
                        case let .connected(deviceID, nick):
                            await send(.peerConnected(deviceID: deviceID, nick: nick))
                        case let .disconnected(deviceID):
                            await send(.peerDisconnected(deviceID: deviceID))
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
