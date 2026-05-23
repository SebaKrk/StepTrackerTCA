//
//  JoinLiveClassFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 23/05/2026.
//

import ComposableArchitecture
import Foundation
import HealthHub
import SharedModels

/// Reducer iPhone'a — dołącza do hosta (iPad) w sieci lokalnej i broadcastuje HR.
///
/// **Proof of Concept**: HR jest **generowany syntetycznie** (random 120-180 co 2s).
/// Real integracja z Watch HR (`HKWorkoutSession` + `WCSession`) → osobny ticket IPAD-0099.
@Reducer
struct JoinLiveClassFeature {

    // MARK: - Dependencies

    @Dependency(\.peerMirrorClient) var peerMirrorClient
    @Dependency(\.continuousClock) var clock

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {

                // MARK: - View Actions

            case .view(.viewDidAppear):
                // Subskrybujemy stream PRZED `joinTapped` — eager subscription
                // zapobiega race condition z `startBrowsing` capturującym
                // jeszcze niezainicjalizowaną continuation.
                return .send(.startObservingPeerEvents)

            case .view(.joinTapped):
                state.phase = .searching
                let nick = state.nick
                return .run { _ in
                    await peerMirrorClient.startBrowsing(nick)
                }

            case .view(.leaveTapped):
                state.phase = .idle
                return .merge(
                    .cancel(id: JoinLiveClassCancelID.hrTimer),
                    .cancel(id: JoinLiveClassCancelID.peerEvents),
                    .run { _ in
                        await peerMirrorClient.stopBrowsing()
                    }
                )

            case .view(.closeTapped):
                return .merge(
                    .send(.view(.leaveTapped)),
                    .send(.delegate(.didDismiss))
                )

                // MARK: - Internal

            case .startObservingPeerEvents:
                return .run { send in
                    for await event in await peerMirrorClient.peerEventsStream() {
                        switch event {
                        case .connected:
                            await send(.peerConnected)
                        case .disconnected:
                            await send(.peerDisconnected)
                        }
                    }
                }
                .cancellable(id: JoinLiveClassCancelID.peerEvents)

            case .peerConnected:
                state.phase = .connected
                return .run { [clock] send in
                    for await _ in clock.timer(interval: .seconds(2)) {
                        await send(.tickHR)
                    }
                }
                .cancellable(id: JoinLiveClassCancelID.hrTimer)

            case .peerDisconnected:
                state.phase = .searching
                return .cancel(id: JoinLiveClassCancelID.hrTimer)

            case .tickHR:
                // Proof of Concept: fake HR generator — TODO IPAD-0099: real Watch HR.
                let bpm = Int.random(in: 120...180)
                let userID = UUID(uuidString: state.userIDString) ?? UUID()
                let payload = HRSamplePayload(
                    userID: userID,
                    nick: state.nick,
                    bpm: bpm,
                    maxHR: 190
                )
                return .run { _ in
                    await peerMirrorClient.send(payload)
                }

                // MARK: - Delegate

            case .delegate:
                return .none
            }
        }
    }
}
