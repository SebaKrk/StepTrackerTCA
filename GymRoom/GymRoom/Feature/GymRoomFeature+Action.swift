//
//  GymRoomFeature+Action.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 23/05/2026.
//

import ComposableArchitecture
import SharedModels

extension GymRoomFeature {

    @CasePathable
    enum Action: ViewAction {

        // MARK: - Internal (peer event handling)

        /// Nowy athlete dołączył — dodaj kafelek. Klucz = `deviceID` (stabilny per-install).
        case peerConnected(deviceID: UUID, nick: String)

        /// Athlete się rozłączył — usuń kafelek po `deviceID`.
        case peerDisconnected(deviceID: UUID)

        /// Nowa próbka HR z iPhone'a athlety — update kafelka.
        case sampleReceived(HRSamplePayload)

        /// Subskrypcja stream'a peer events z `peerMirrorClient`.
        case startObservingPeerEvents

        /// Subskrypcja stream'a HR samples z `peerMirrorClient`.
        case startObservingSamples

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
