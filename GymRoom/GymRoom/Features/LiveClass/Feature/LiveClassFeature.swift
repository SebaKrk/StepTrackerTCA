//
//  LiveClassFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 11/06/2026.
//


//
//  LiveClassFeature.swift
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
LiveClassFeature {

    // MARK: - Dependencies

    @Dependency(\.peerMirrorClient) var peerMirrorClient
    @Dependency(\.gymClassClient) var gymClassClient
    @Dependency(\.continuousClock) var clock

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {

                // MARK: - View Actions

            case .view(.viewDidAppear):
                // Auto-start klasę gdy fullScreenCover pojawia się — user explicit tap'nął
                // "Start class" w ClassDetailView, ten View jest **live mode**, nie state
                // machine z idle phase. Idle UI w body jest defensive fallback gdyby
                // auto-startTapped fail'owało.
                Logger.gymRoom.info("🎬 LiveClassView appeared — starting observations + auto-start")
                return .merge(
                    .send(.startObservingPeerEvents),
                    .send(.startObservingSamples),
                    .send(.view(.startTapped))
                )

            case .view(.startTapped):
                // Idempotency guard — viewDidAppear auto-triggers, ale user może też explicit tap
                // (defensive). Drugi call gdy isLive=true = no-op (zachowujemy sessionToken).
                guard !state.isLive else { return .none }
                let gymName = state.className
                let location = state.location
                let gymClassId = state.gymClassId
                Logger.gymRoom.info("▶️ Start tapped — advertising as '\(gymName)'")
                state.isLive = true
                let token = UUID()
                state.sessionToken = token    // fresh token per class — encoded w QR
                state.isQRVisible = true
                return .merge(
                    .run { send in
                        // Persist session record + propagate id back do State dla athlete inserts.
                        do {
                            let sessionId = try await gymClassClient.startSession(gymClassId, gymName, location)
                            await send(.sessionStarted(sessionId: sessionId))
                        } catch {
                            Logger.gymRoom.error("❌ startSession failed: \(error.localizedDescription)")
                        }
                        await peerMirrorClient.startAdvertising(gymName, token)
                    },
                    .send(.delegate(.classStarted))
                )

            case let .sessionStarted(sessionId):
                Logger.gymRoom.info("💾 Session started — id: \(sessionId.uuidString.prefix(8))")
                state.activeSessionId = sessionId
                // Start batch persistence timer — flush HR buffers do BLOB co 30s.
                return .run { send in
                    for await _ in clock.timer(interval: .seconds(30)) {
                        await send(.flushBufferedSamples)
                    }
                }
                .cancellable(id: LiveClassCancelID.persistenceTimer)

            case .view(.endTapped):
                // Tap End → present confirm dialog. Faktyczna end logic w `.alert(.presented(.confirmEnd))`.
                // Alert content w `LiveClassFeature+AlertState.swift` jako static `.endClass`.
                state.alert = .endClass
                return .none

            case .alert(.presented(.confirmEnd)):
                Logger.gymRoom.info("⏹️ End confirmed — flushing buffers + finalizing session")
                // Snapshot persistence state PRZED clearowaniem — async effects używają snapshot.
                let sessionId = state.activeSessionId
                let buffer = state.hrSamplesBuffer
                let mappings = state.athleteRecordIds
                let endedAt = Date()

                state.isLive = false
                state.athletes.removeAll()
                state.sessionToken = nil
                state.activeSessionId = nil
                state.hrSamplesBuffer = [:]
                state.athleteRecordIds = [:]
                return .merge(
                    .run { _ in
                        // 1. Flush remaining buffer per athlete (samples z ostatnich <30s).
                        for (deviceID, samples) in buffer where !samples.isEmpty {
                            guard let athleteId = mappings[deviceID] else { continue }
                            do {
                                try await gymClassClient.appendHRSamples(athleteId, samples)
                            } catch {
                                Logger.gymRoom.error("❌ final flush failed for \(deviceID.uuidString.prefix(8)): \(error.localizedDescription)")
                            }
                        }
                        // 2. End session (sam finalize'uje wszystkich ongoing athletes z analytics).
                        if let sessionId {
                            do {
                                try await gymClassClient.endSession(sessionId, endedAt)
                            } catch {
                                Logger.gymRoom.error("❌ endSession failed: \(error.localizedDescription)")
                            }
                        }
                        await peerMirrorClient.stopAdvertising()
                    },
                    .cancel(id: LiveClassCancelID.persistenceTimer),
                    .send(.delegate(.classEnded))
                )

            case .alert:
                // Cancel lub dismiss — nic do roboty, presentation reducer sam clearuje state.alert.
                return .none

            case .delegate:
                return .none

            case .view(.toggleQR):
                state.isQRVisible.toggle()
                return .none

                // MARK: - Internal

            case let .peerConnected(deviceID, nick):
                Logger.gymRoom.info("✅ Peer connected: \(nick) (deviceID: \(deviceID.uuidString.prefix(8)))")
                guard state.athletes[id: deviceID] == nil else { return .none }
                state.athletes.append(AthleteTile(id: deviceID, nick: nick))
                // Persist athlete do DB. maxHR=190 to default fallback — real maxHR
                // jest w każdej HR próbce (payload.maxHR), ale snapshot w DB to MVP
                // simplification (osobny ticket dla precise per-athlete maxHR update).
                guard let sessionId = state.activeSessionId else { return .none }
                return .run { send in
                    do {
                        let athleteId = try await gymClassClient.addAthlete(sessionId, deviceID, nick, 190)
                        await send(.athleteAdded(deviceID: deviceID, athleteId: athleteId))
                    } catch {
                        Logger.gymRoom.error("❌ addAthlete failed for \(nick): \(error.localizedDescription)")
                    }
                }

            case let .athleteAdded(deviceID, athleteId):
                state.athleteRecordIds[deviceID] = athleteId
                state.hrSamplesBuffer[deviceID] = []
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
                // Snapshot remaining buffer + athleteId PRZED clearowaniem.
                let samples = state.hrSamplesBuffer[deviceID] ?? []
                let athleteId = state.athleteRecordIds[deviceID]
                let leftAt = Date()

                state.athletes.remove(id: deviceID)
                state.hrSamplesBuffer[deviceID] = nil
                state.athleteRecordIds[deviceID] = nil

                return .run { _ in
                    guard let athleteId else { return }
                    // Flush remaining buffered samples PRZED endAthlete (żeby compute analytics
                    // używał kompletnego BLOB stream'a). Idempotent — empty samples no-op.
                    if !samples.isEmpty {
                        try? await gymClassClient.appendHRSamples(athleteId, samples)
                    }
                    try? await gymClassClient.endAthlete(athleteId, leftAt)
                }

            case let .sampleReceived(payload):
                guard var tile = state.athletes[id: payload.deviceID] else { return .none }
                tile.bpm = payload.bpm
                tile.maxHR = payload.maxHR
                tile.activeEnergy = payload.activeEnergy
                state.athletes[id: payload.deviceID] = tile

                // Buffer HRSample dla batch persistence (flush co 30s przez persistenceTimer).
                let sample = HRSample(
                    timestamp: payload.timestamp,
                    bpm: payload.bpm,
                    activeEnergy: payload.activeEnergy
                )
                state.hrSamplesBuffer[payload.deviceID, default: []].append(sample)
                Logger.gymRoom.debug("💓 Updated \(payload.nick): \(payload.bpm) bpm")
                return .none

            case .flushBufferedSamples:
                // Snapshot buffer + clear (next batch zaczyna od pustego). Async write
                // do BLOB per athlete. Race-safe: SQLite write block serialized.
                let snapshot = state.hrSamplesBuffer
                state.hrSamplesBuffer = snapshot.mapValues { _ in [] }
                let mappings = state.athleteRecordIds
                return .run { _ in
                    for (deviceID, samples) in snapshot where !samples.isEmpty {
                        guard let athleteId = mappings[deviceID] else { continue }
                        do {
                            try await gymClassClient.appendHRSamples(athleteId, samples)
                        } catch {
                            Logger.gymRoom.error("❌ flush failed for \(deviceID.uuidString.prefix(8)): \(error.localizedDescription)")
                        }
                    }
                }

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
                        case .classEnded:
                            // Host-side no-op: iPad sam emit'uje classEnded broadcast
                            // (via PeerMirrorBLEHostSession.broadcastClassEnded), własny event
                            // nie wymaga reakcji w reducerze (host już wie że robi END).
                            break
                        }
                    }
                }
                .cancellable(id: LiveClassCancelID.peerEvents)

            case .startObservingSamples:
                Logger.gymRoom.info("🔥 Starting samples observation...")
                return .run { send in
                    for await sample in await peerMirrorClient.samplesStream() {
                        await send(.sampleReceived(sample))
                    }
                }
                .cancellable(id: LiveClassCancelID.samples)
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
