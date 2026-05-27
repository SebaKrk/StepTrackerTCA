//
//  JoinLiveClassFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 23/05/2026.
//

import ComposableArchitecture
import Foundation
import HealthHub
import OSLog
import SharedModels

/// Reducer iPhone'a — dołącza do hosta (iPad) w sieci lokalnej i broadcastuje real HR
/// z Apple Watcha (przez `TrainingManager.workoutMetricsStream`).
///
/// **Wymaganie**: user musi mieć aktywną workout session na Watchu — bez niej
/// `HKLiveWorkoutBuilder` nie zbiera HR i `WorkoutMetrics` events nie lecą.
@Reducer
struct JoinLiveClassFeature {

    // MARK: - Dependencies

    @Dependency(\.peerMirrorClient) var peerMirrorClient
    @Dependency(\.trainingManager) var trainingManager
    @Dependency(\.userProfileClient) var userProfileClient

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {

                // MARK: - View Actions

            case .view(.viewDidAppear):
                // Subskrybujemy stream PRZED `joinTapped` — eager subscription
                // zapobiega race condition z `startBrowsing` capturującym
                // jeszcze niezainicjalizowaną continuation.
                // Plus: fetch user profile żeby ustawić display name (nickname → name → fallback).
                return .merge(
                    .send(.startObservingPeerEvents),
                    .run { [userProfileClient] send in
                        let profile = try? await userProfileClient.fetch()
                        await send(.userProfileLoaded(profile))
                    }
                )

            case .view(.joinTapped):
                // Start browsing + zamknij sheet od razu. Broadcast trwa w tle,
                // ikona toolbar SessionView pokazuje connected. User otworzy sheet
                // ponownie klikając ikonę → zobaczy stan + Leave button.
                state.phase = .searching
                let nick = state.nick
                return .merge(
                    .run { _ in await peerMirrorClient.startBrowsing(nick) },
                    .send(.delegate(.didDismiss))
                )

            case .view(.leaveTapped):
                // "Zakończ klasę" — broadcast stop + delegate.didLeave (parent kasuje state).
                state.phase = .idle
                return .merge(
                    .cancel(id: JoinLiveClassCancelID.hrStream),
                    .cancel(id: JoinLiveClassCancelID.peerEvents),
                    .run { _ in
                        await peerMirrorClient.stopBrowsing()
                    },
                    .send(.delegate(.didLeave))
                )

            case .view(.closeTapped):
                // Sheet schowany (X / swipe-down) — broadcast TRWA, state żyje, ikona toolbar
                // pozostaje "connected". User otworzy sheet znowu klikając ikonę.
                return .send(.delegate(.didDismiss))

                // MARK: - Internal

            case let .userProfileLoaded(profile):
                // Fallback chain: nickname → name → keep current ("Athlete-XXX" z AppStorage).
                // Nigdy nie nadpisujemy `state.nick` pustym stringiem.
                if let profile {
                    Logger.gymRoom.info("[Profile] loaded: name='\(profile.name)' surname='\(profile.surname)' nickname='\(profile.nickname)'")
                } else {
                    Logger.gymRoom.info("[Profile] NIL — no UserProfile in database")
                }
                guard let profile else { return .none }
                if !profile.nickname.isEmpty {
                    Logger.gymRoom.info("[Profile] using nickname: '\(profile.nickname)'")
                    state.$nick.withLock { $0 = profile.nickname }
                } else if !profile.name.isEmpty {
                    Logger.gymRoom.info("[Profile] using name: '\(profile.name)'")
                    state.$nick.withLock { $0 = profile.name }
                } else {
                    Logger.gymRoom.info("[Profile] both nickname and name empty — keeping default '\(state.nick)'")
                }
                return .none

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
                Logger.gymRoom.info("[Peer] connected — starting workoutMetricsStream subscription")
                state.phase = .connected
                let nick = state.nick
                let userIDString = state.userIDString
                let maxHR = state.maxHeartRate
                return .run { [trainingManager, peerMirrorClient] _ in
                    for await metrics in trainingManager.workoutMetricsStream {
                        Logger.gymRoom.debug("[Peer] metrics received HR=\(Int(metrics.heartRate))")
                        guard metrics.heartRate > 0 else { continue }
                        let userUUID = UUID(uuidString: userIDString) ?? UUID()
                        let payload = HRSamplePayload(
                            userID: userUUID,
                            nick: nick,
                            bpm: Int(metrics.heartRate),
                            maxHR: maxHR,
                            activeEnergy: metrics.activeEnergy
                        )
                        Logger.gymRoom.debug("[Peer] forwarding to iPad: \(Int(metrics.heartRate)) bpm, \(metrics.activeEnergy) kcal")
                        await peerMirrorClient.send(payload)
                    }
                }
                .cancellable(id: JoinLiveClassCancelID.hrStream)

            case .peerDisconnected:
                Logger.gymRoom.info("[Peer] disconnected — cancelling HR stream, returning to searching")
                state.phase = .searching
                return .cancel(id: JoinLiveClassCancelID.hrStream)

                // MARK: - Delegate

            case .delegate:
                return .none
            }
        }
    }
}
