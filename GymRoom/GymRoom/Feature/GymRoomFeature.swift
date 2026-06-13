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
                // Extract value PRZED Logger call — Logger.info ma @escaping autoclosure
                // który nie może capture'ować inout state z reducer closure.
                let gymName = state.gymName
                Logger.gymRoom.info("▶️ Start tapped — advertising as '\(gymName)'")
                state.isLive = true
                let token = UUID()
                state.sessionToken = token    // fresh token per class — encoded w QR
                state.isQRVisible = true      // reset visibility on new class
                return .run { _ in
                    await peerMirrorClient.startAdvertising(gymName, token)
                }

            case .view(.endTapped):
                // Tap End → present confirm dialog. Faktyczna end logic w `.alert(.presented(.confirmEnd))`.
                state.alert = AlertState(
                    title: { TextState(String(localized: "End class?", bundle: .main)) },
                    actions: {
                        ButtonState(role: .destructive, action: .confirmEnd) {
                            TextState(String(localized: "End", bundle: .main))
                        }
                        ButtonState(role: .cancel) {
                            TextState(String(localized: "Cancel", bundle: .main))
                        }
                    },
                    message: { TextState(String(localized: "All athletes will be disconnected.", bundle: .main)) }
                )
                return .none

            case .alert(.presented(.confirmEnd)):
                Logger.gymRoom.info("⏹️ End confirmed — invalidating session token")
                state.isLive = false
                state.athletes.removeAll()
                state.sessionToken = nil      // invalidate — stale QR scans odrzucone (subtask C3)
                return .run { _ in
                    await peerMirrorClient.stopAdvertising()
                }

            case .alert:
                // Cancel lub dismiss — nic do roboty, presentation reducer sam clearuje state.alert.
                return .none

            case .view(.toggleQR):
                state.isQRVisible.toggle()
                return .none

                // MARK: - Internal

            case let .peerConnected(deviceID, nick):
                Logger.gymRoom.info("✅ Peer connected: \(nick) (deviceID: \(deviceID.uuidString.prefix(8)))")
                guard state.athletes[id: deviceID] == nil else { return .none }
                state.athletes.append(AthleteTile(id: deviceID, nick: nick))
                return .none

            case let .peerSuspended(deviceID):
                // Grace period — peer może jeszcze wrócić w ciągu 10s. Tile zostaje
                // widoczny ale w stanie `.reconnecting` (spinner overlay + grayscale).
                Logger.gymRoom.info("⏸ Peer suspended: \(deviceID.uuidString.prefix(8)) — entering grace period")
                state.athletes[id: deviceID]?.state = .reconnecting
                return .none

            case let .peerReconnected(deviceID):
                // Peer wrócił w oknie — restore stan `.live`. Brak animacji "appear",
                // tylko subtelny return spinner → normal.
                Logger.gymRoom.info("🔄 Peer reconnected: \(deviceID.uuidString.prefix(8))")
                state.athletes[id: deviceID]?.state = .live
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
                        case let .suspended(deviceID, _):
                            await send(.peerSuspended(deviceID: deviceID))
                        case let .reconnected(deviceID, _):
                            await send(.peerReconnected(deviceID: deviceID))
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
        .ifLet(\.$alert, action: \.alert)
    }
}
