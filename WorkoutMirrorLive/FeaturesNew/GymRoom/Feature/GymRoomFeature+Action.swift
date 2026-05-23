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

        /// Nowy athlete dołączył — dodaj kafelek.
        case peerConnected(nick: String)

        /// Athlete się rozłączył — usuń kafelek.
        case peerDisconnected(nick: String)

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
        }
    }
}
