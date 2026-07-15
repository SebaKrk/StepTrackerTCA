//
//  LiveClassFeature.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 11/06/2026.
//

import AppDatabase
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
struct LiveClassFeature {

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
                /// Auto-start klasę gdy fullScreenCover pojawia się — user explicit tap'nął
                /// "Start class" w ClassDetailView, ten View jest **live mode**, nie state
                /// machine z idle phase. Idle UI w body jest defensive fallback gdyby
                /// auto-startTapped fail'owało.
                Logger.gymRoom.info("🎬 LiveClassView appeared — starting observations + auto-start")
                return .merge(
                    .send(.startObservingPeerEvents),
                    .send(.startObservingSamples),
                    .send(.view(.startTapped))
                )

            case .view(.startTapped):
                /// Idempotency guard — viewDidAppear auto-triggers, ale user może też explicit tap
                /// (defensive). Drugi call gdy isLive=true = no-op (zachowujemy sessionToken).
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
                        /// Nowy plik log per class — reset PRZED czymkolwiek innym żeby header
                        /// miał poprawny startDate. Wszystkie poniższe log'i trafiają do nowego pliku.
                        await GymRoomFileLogger.shared.reset()
                        await GymRoomFileLogger.shared.log("[Class] start: name=\(gymName), location=\(location)")
                        /// Persist session record + propagate id back do State dla athlete inserts.
                        do {
                            let sessionId = try await gymClassClient.startSession(gymClassId, gymName, location)
                            await send(.sessionStarted(sessionId: sessionId))
                        } catch {
                            Logger.gymRoom.error("❌ startSession failed: \(error.localizedDescription)")
                            await GymRoomFileLogger.shared.log("[Class] ERROR startSession failed: \(error.localizedDescription)")
                        }
                        await peerMirrorClient.startAdvertising(gymName, token)
                        await GymRoomFileLogger.shared.log("[Class] BLE advertising started: token=\(token.uuidString.prefix(8))")
                    },
                    .send(.delegate(.classStarted))
                )

            case let .sessionStarted(sessionId):
                Logger.gymRoom.info("💾 Session started — id: \(sessionId.uuidString.prefix(8))")
                let sessionIdShort = sessionId.uuidString.prefix(8)
                state.activeSessionId = sessionId
                /// Start batch persistence timer — flush HR buffers do BLOB co 30s.
                return .merge(
                    .run { _ in
                        await GymRoomFileLogger.shared.log("[Session] persisted: id=\(sessionIdShort)")
                    },
                    .run { send in
                        for await _ in clock.timer(interval: .seconds(30)) {
                            await send(.flushBufferedSamples)
                        }
                    }
                    .cancellable(id: LiveClassCancelID.persistenceTimer)
                )

            case .view(.endTapped):
                /// Tap End → present confirm dialog. Faktyczna end logic w `.alert(.presented(.confirmEnd))`.
                /// Alert content w `LiveClassFeature+AlertState.swift` jako static `.endClass`.
                state.alert = .endClass
                return .none

            case .alert(.presented(.confirmEnd)):
                Logger.gymRoom.info("⏹️ End confirmed — flushing buffers + finalizing session")
                /// Snapshot persistence state PRZED clearowaniem — async effects używają snapshot.
                let sessionId = state.activeSessionId
                let buffer = state.hrSamplesBuffer
                let mappings = state.athleteRecordIds
                let endedAt = Date()
                let classLatitude = state.latitude
                let classLongitude = state.longitude

                state.isLive = false
                state.athletes.removeAll()
                state.sessionToken = nil
                state.activeSessionId = nil
                state.hrSamplesBuffer = [:]
                state.athleteRecordIds = [:]
                state.athleteCreationInFlight = []
                return .merge(
                    .cancel(id: LiveClassCancelID.persistenceTimer),
                    .run { send in
                        await GymRoomFileLogger.shared.log("[Class] end: confirmed by trainer, finalizing")
                        /// 1. Flush remaining buffer per athlete (samples z ostatnich <30s).
                        for (deviceID, samples) in buffer where !samples.isEmpty {
                            guard let athleteId = mappings[deviceID] else { continue }
                            do {
                                try await gymClassClient.appendHRSamples(athleteId, samples)
                            } catch {
                                Logger.gymRoom.error("❌ final flush failed for \(deviceID.uuidString.prefix(8)): \(error.localizedDescription)")
                                await GymRoomFileLogger.shared.log("[Class] ERROR final flush failed for \(deviceID.uuidString.prefix(8)): \(error.localizedDescription)")
                            }
                        }
                        /// 2. End session (sam finalize'uje wszystkich ongoing athletes z analytics).
                        if let sessionId {
                            do {
                                try await gymClassClient.endSession(sessionId, endedAt)
                                await GymRoomFileLogger.shared.log("[Session] ended: id=\(sessionId.uuidString.prefix(8))")
                            } catch {
                                Logger.gymRoom.error("❌ endSession failed: \(error.localizedDescription)")
                                await GymRoomFileLogger.shared.log("[Class] ERROR endSession failed: \(error.localizedDescription)")
                            }
                        }
                        /// 3. Recap + ranking. Fetch athletes PRZED `stopAdvertising` — recap
                        /// leci per-device przez WCIĄŻ ŻYWE połączenia BLE (IOS-00104-C). Analytics
                        /// są FROZEN w bazie (`endSession`), więc te same `rows` zasilają i recap,
                        /// i tabelę wyników.
                        var resultRows: [ClassResultsFeature.ResultRow] = []
                        if let sessionId {
                            do {
                                let records = try await gymClassClient.fetchAthletesForSession(sessionId)
                                let rows = ClassResultsFeature.rows(from: records)
                                resultRows = rows
                                // Miejsce z rankingu (points desc); deviceID z rekordu athlety.
                                let ranked = rows.sorted { $0.points > $1.points }
                                let placeByAthlete = Dictionary(
                                    uniqueKeysWithValues: ranked.enumerated().map { ($0.element.id, $0.offset + 1) }
                                )
                                let deviceByAthlete = Dictionary(
                                    records.map { ($0.id, $0.deviceID) },
                                    uniquingKeysWith: { first, _ in first }
                                )
                                for row in rows {
                                    guard let deviceID = deviceByAthlete[row.id],
                                          let place = placeByAthlete[row.id] else { continue }
                                    let recap = ClassRecapPayload(
                                        deviceID: deviceID,
                                        classSessionId: sessionId,
                                        place: place,
                                        participantCount: rows.count,
                                        latitude: classLatitude,
                                        longitude: classLongitude
                                    )
                                    await peerMirrorClient.sendRecap(recap, deviceID)
                                }
                                await GymRoomFileLogger.shared.log("[Class] recap sent to \(rows.count) athletes")
                            } catch {
                                Logger.gymRoom.error("❌ results/recap fetch failed: \(error.localizedDescription)")
                                await GymRoomFileLogger.shared.log("[Class] ERROR results/recap fetch failed: \(error.localizedDescription)")
                            }
                        }
                        /// Recap wysłany — dopiero teraz zamknij BLE (rozłączenie ucina notify).
                        await peerMirrorClient.stopAdvertising()
                        await GymRoomFileLogger.shared.log("[Class] BLE advertising stopped")
                        /// Tabela wyników (IPAD-00095-A). `delegate(.classEnded)` poleci dopiero z
                        /// "Done" w tabeli. Fallback (błąd fetchu / brak zawodników): zamknij od razu,
                        /// trener nigdy nie utknie.
                        if !resultRows.isEmpty {
                            await send(.resultsReady(resultRows))
                            return
                        }
                        await send(.delegate(.classEnded))
                    }
                )

            case let .resultsReady(rows):
                state.results = ClassResultsFeature.State(className: state.className, rows: rows)
                return .none

            case .results(.presented(.delegate(.done))):
                state.results = nil
                return .send(.delegate(.classEnded))

            case .results:
                return .none

            case .alert:
                /// Cancel lub dismiss — nic do roboty, presentation reducer sam clearuje state.alert.
                return .none

            case .delegate:
                return .none

            case .view(.toggleQR):
                state.isQRVisible.toggle()
                return .none

                // MARK: - Internal

            case let .peerConnected(deviceID, nick):
                /// **Lazy persistence pattern**: BLE handshake event NIE tworzy jeszcze DB record.
                /// Przy handshake brak `maxHR` (przychodzi dopiero w pierwszym HRSamplePayload).
                /// Tworzenie tu = fake maxHR=190 placeholder. Lazy: tile od razu z `.loading`
                /// state, DB CREATE dopiero przy pierwszym `sampleReceived` z real `payload.maxHR`.
                Logger.gymRoom.info("✅ Peer handshake: \(nick) (deviceID: \(deviceID.uuidString.prefix(8)))")
                let deviceShort = deviceID.uuidString.prefix(8)
                guard state.athletes[id: deviceID] == nil else {
                    /// Tile już istnieje — log + skip (rzadki edge case, ignore).
                    return .run { _ in
                        await GymRoomFileLogger.shared.log("[Peer] handshake (tile already exists, skipping): nick=\(nick) deviceID=\(deviceShort)")
                    }
                }
                /// Loading tile — bpm=0 + spinner overlay aż przyjdzie pierwszy sample.
                state.athletes.append(AthleteTile(id: deviceID, nick: nick, state: .loading))
                state.hrSamplesBuffer[deviceID] = []
                return .run { _ in
                    await GymRoomFileLogger.shared.log("[Peer] handshake (awaiting first sample): nick=\(nick) deviceID=\(deviceShort)")
                }

            case let .athleteAdded(deviceID, athleteId):
                state.athleteRecordIds[deviceID] = athleteId
                state.hrSamplesBuffer[deviceID] = []
                state.athleteCreationInFlight.remove(deviceID)
                return .none

            case let .athleteCreationFailed(deviceID):
                // Create failed — release the claim so a later sample retries.
                state.athleteCreationInFlight.remove(deviceID)
                return .none

            case let .peerSuspended(deviceID):
                /// Grace period — peer może jeszcze wrócić w ciągu 10s. Tile zostaje
                /// widoczny ale w stanie `.reconnecting` (spinner overlay + grayscale).
                Logger.gymRoom.info("⏸ Peer suspended: \(deviceID.uuidString.prefix(8)) — entering grace period")
                let deviceShort = deviceID.uuidString.prefix(8)
                state.athletes[id: deviceID]?.state = .reconnecting
                return .run { _ in
                    await GymRoomFileLogger.shared.log("[Peer] suspended (grace period): deviceID=\(deviceShort)")
                }

            case let .peerReconnected(deviceID):
                /// Peer wrócił w oknie — restore stan `.live`. Brak animacji "appear",
                /// tylko subtelny return spinner → normal.
                Logger.gymRoom.info("🔄 Peer reconnected: \(deviceID.uuidString.prefix(8))")
                let deviceShort = deviceID.uuidString.prefix(8)
                state.athletes[id: deviceID]?.state = .live
                return .run { _ in
                    await GymRoomFileLogger.shared.log("[Peer] reconnected: deviceID=\(deviceShort)")
                }

            case let .peerDisconnected(deviceID):
                Logger.gymRoom.info("❌ Peer disconnected: \(deviceID.uuidString.prefix(8))")
                let deviceShort = deviceID.uuidString.prefix(8)
                /// Snapshot remaining buffer + athleteId PRZED clearowaniem.
                let samples = state.hrSamplesBuffer[deviceID] ?? []
                let athleteId = state.athleteRecordIds[deviceID]
                let leftAt = Date()

                state.athletes.remove(id: deviceID)
                state.hrSamplesBuffer[deviceID] = nil
                state.athleteRecordIds[deviceID] = nil

                return .run { _ in
                    await GymRoomFileLogger.shared.log("[Peer] left: deviceID=\(deviceShort), bufferedSamples=\(samples.count)")
                    guard let athleteId else { return }
                    /// Flush remaining buffered samples PRZED endAthlete (żeby compute analytics
                    /// używał kompletnego BLOB stream'a). Idempotent — empty samples no-op.
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
                // Device-computed cumulative counter — keep the last known value
                // when a payload arrives without it (goodbye from an old build).
                if let effortPoints = payload.effortPoints {
                    tile.effortPoints = effortPoints
                }
                // Sensor freshness (IOS-00100-C) — `nil` from a legacy peer build
                // means "no staleness info", treated as fresh.
                tile.isSensorStale = payload.isSensorStale ?? false

                /// Buffer HRSample dla batch persistence (flush co 30s przez persistenceTimer).
                /// Stale payloads (IOS-00100-C) are presence keepalives carrying the
                /// frozen last-known value — persisting them would fake continuity in
                /// the class history; the honest gap is handled by the gap-aware charts.
                if payload.isSensorStale != true {
                    let sample = HRSample(
                        timestamp: payload.timestamp,
                        bpm: payload.bpm,
                        activeEnergy: payload.activeEnergy,
                        effortPoints: payload.effortPoints
                    )
                    state.hrSamplesBuffer[payload.deviceID, default: []].append(sample)
                }
                Logger.gymRoom.debug("💓 Updated \(payload.nick): \(payload.bpm) bpm\(payload.isSensorStale == true ? " (STALE)" : "")")

                /// **First-sample CREATE pattern**: tile w `.loading` + brak athleteId =
                /// to PIERWSZY payload od tego peer'a. Teraz mamy real `payload.maxHR`
                /// — CREATE record w bazie z prawdziwą wartością (NIE fake 190).
                /// Resume check też tu — jeśli ten deviceID był już w sesji (wybiegł
                /// poza grace period i wraca), reuse jego ID zamiast tworzyć nowy.
                if state.athleteRecordIds[payload.deviceID] == nil,
                   !state.athleteCreationInFlight.contains(payload.deviceID) {
                    tile.state = .live
                    state.athletes[id: payload.deviceID] = tile
                    guard let sessionId = state.activeSessionId else { return .none }
                    // Claim BEFORE dispatching the async create — a second sample
                    // arriving before `.athleteAdded` lands must not spawn a second
                    // create (duplicate athlete record in the class results).
                    state.athleteCreationInFlight.insert(payload.deviceID)
                    let deviceID = payload.deviceID
                    let deviceShort = deviceID.uuidString.prefix(8)
                    let nick = tile.nick
                    let realMaxHR = payload.maxHR
                    return .run { send in
                        if let existingId = try? await gymClassClient.findAthlete(sessionId, deviceID) {
                            try? await gymClassClient.resumeAthlete(existingId)
                            await send(.athleteAdded(deviceID: deviceID, athleteId: existingId))
                            await GymRoomFileLogger.shared.log("[Peer] resumed: nick=\(nick) deviceID=\(deviceShort) realMaxHR=\(realMaxHR)")
                        } else {
                            do {
                                let athleteId = try await gymClassClient.addAthlete(sessionId, deviceID, nick, realMaxHR)
                                await send(.athleteAdded(deviceID: deviceID, athleteId: athleteId))
                                await GymRoomFileLogger.shared.log("[Peer] joined: nick=\(nick) deviceID=\(deviceShort) realMaxHR=\(realMaxHR)")
                            } catch {
                                Logger.gymRoom.error("❌ addAthlete failed for \(nick): \(error.localizedDescription)")
                                await GymRoomFileLogger.shared.log("[Peer] ERROR addAthlete failed for \(nick): \(error.localizedDescription)")
                                // Re-arm the claim so the next sample can retry the create.
                                await send(.athleteCreationFailed(deviceID: deviceID))
                            }
                        }
                    }
                }

                state.athletes[id: payload.deviceID] = tile
                return .none

            case .flushBufferedSamples:
                /// Snapshot buffer + clear (next batch zaczyna od pustego). Async write
                /// do BLOB per athlete. Race-safe: SQLite write block serialized.
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
                            /// Host-side no-op: iPad sam emit'uje classEnded broadcast
                            /// (via PeerMirrorBLEHostSession.broadcastClassEnded), własny event
                            /// nie wymaga reakcji w reducerze (host już wie że robi END).
                            break
                        case .recapReceived:
                            /// Host-side no-op: recap płynie iPad→uczestnik (host wysyła,
                            /// nie odbiera). Ten event pojawia się tylko peer-side.
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
        .ifLet(\.$results, action: \.results) {
            ClassResultsFeature()
        }
    }
}
