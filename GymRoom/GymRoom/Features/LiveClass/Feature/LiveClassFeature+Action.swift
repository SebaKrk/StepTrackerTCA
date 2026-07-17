//
//  LiveClassFeature+Action.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 23/05/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

extension LiveClassFeature {

    @CasePathable
    enum Action: ViewAction {

        // MARK: - Alert (END Class confirmation)

        /// Akcje z alert'u — confirm END Class lub cancel (PresentationAction wraps obie).
        case alert(PresentationAction<Alert>)

        /// Wybory użytkownika w alert'cie END Class.
        enum Alert: Equatable {
            /// Trener potwierdził chęć zakończenia klasy — uruchom end logic.
            case confirmEnd
        }

        // MARK: - Internal (peer event handling)

        /// Nowy athlete dołączył — dodaj kafelek. Klucz = `deviceID` (stabilny per-install).
        case peerConnected(deviceID: UUID, nick: String)

        /// Athlete BLE-unsubscribed — wchodzi w grace period (10s). Kafelek **nie znika**,
        /// tylko zmienia stan na `.reconnecting` (spinner overlay + grayscale).
        /// Service emit'uje `.peerReconnected` jeśli peer wraca w oknie, lub `.peerDisconnected`
        /// po timeout.
        case peerSuspended(deviceID: UUID)

        /// Athlete wrócił w grace window — kafelek wraca do `.live` state.
        case peerReconnected(deviceID: UUID)

        /// Athlete faktycznie zaginął (grace timeout, host stop, lub explicit drop).
        /// Reducer usuwa kafelek z `state.athletes`.
        case peerDisconnected(deviceID: UUID)

        /// Nowa próbka HR z iPhone'a athlety — update kafelka.
        case sampleReceived(HRSamplePayload)

        /// Subskrypcja stream'a peer events z `peerMirrorClient`.
        case startObservingPeerEvents

        /// Subskrypcja stream'a HR samples z `peerMirrorClient`.
        case startObservingSamples

        // MARK: - Internal (persistence)

        /// Po `gymClassClient.startSession(...)` success — set `state.activeSessionId` +
        /// start `persistenceTimer` effect (flush buffer co 30s).
        case sessionStarted(sessionId: UUID)

        /// Po `gymClassClient.addAthlete(...)` success — assign `athleteId` do
        /// `state.athleteRecordIds[deviceID]`, initialize empty buffer.
        case athleteAdded(deviceID: UUID, athleteId: UUID)

        /// The create effect failed — releases the `athleteCreationInFlight`
        /// claim so the next incoming sample can retry.
        case athleteCreationFailed(deviceID: UUID)

        /// Timer tick z `persistenceTimer` effect (co 30s) — flush buffered samples
        /// per athlete (`appendHRSamples` async per peer), clear buffer.
        case flushBufferedSamples

        /// Timer tick z `sensorWatchdog` effect (co 5s) — mark tiles with no
        /// payload for over `sampleStaleThreshold` as stale. Covers the case
        /// where the peer stops sending entirely (app killed, HealthKit stall)
        /// while its BLE subscription stays alive, so `isSensorStale` would
        /// never arrive from the peer itself.
        case sensorWatchdogTick

        // MARK: - Results (IPAD-00095-A)

        /// Ranking rows zbudowane z FROZEN analytics po `endSession` — prezentuje
        /// tabelę wyników jako fullScreenCover.
        case resultsReady([ClassResultsFeature.ResultRow])

        /// Presentation dla tabeli wyników. `delegate(.done)` z childa wznawia
        /// stary flow zamknięcia klasy (`delegate(.classEnded)` do parenta).
        case results(PresentationAction<ClassResultsFeature.Action>)

        // MARK: - Delegate (parent — ClassesListFeature)

        /// Komunikaty do parent reducer'a (ClassesListFeature). Parent reaguje:
        /// `.classEnded` → set state.liveClass = nil + mark current .live class as .past.
        case delegate(Delegate)

        enum Delegate: Equatable {
            /// User tap "Start class" — parent (ClassesListFeature) mark gymClass.phase = .live.
            case classStarted

            /// User End → confirm — parent close fullScreenCover + mark gymClass.phase = .past.
            case classEnded
        }

        // MARK: - View Actions

        case view(View)

        enum View {

            /// Pierwsze pojawienie się widoku — start subskrypcji streamów.
            case viewDidAppear

            /// Tap "Start class" — iPad zaczyna advertising w sieci lokalnej.
            case startTapped

            /// Tap "End" — iPad przestaje advertising, czyści listę athletów.
            case endTapped

            /// Toggle widoczności QR widgetu (corner overlay). Trener może schować QR
            /// po dołączeniu wszystkich sportowców — sam ikonowy button zostaje
            /// w corner żeby można było pokazać znowu.
            case toggleQR
        }
    }
}
