//
//  JoinLiveClassFeature+Action.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 23/05/2026.
//

import ComposableArchitecture

extension JoinLiveClassFeature {

    @CasePathable
    enum Action: ViewAction {

        // MARK: - Internal

        /// Subskrypcja peer events stream z `peerMirrorClient`.
        case startObservingPeerEvents

        /// Peer (iPad host) connected — switch phase do `.connected`, start HR timer.
        case peerConnected

        /// Peer disconnected — stop HR timer, phase do `.idle`.
        case peerDisconnected

        /// Tick HR timera (co ~2s) — wyślij fake HR payload do iPada.
        /// TODO IPAD-0099: zastąp real Watch HR samples (WCSession integration).
        case tickHR

        // MARK: - View Actions

        case view(View)

        enum View {

            /// Pierwsze pojawienie się sheeta — subskrypcja peer events stream
            /// (przed `joinTapped` żeby uniknąć race condition z capturing continuation).
            case viewDidAppear

            /// Tap "Join Live Class" — startBrowsing (stream jest już subscribed w viewDidAppear).
            case joinTapped

            /// Tap "Leave" — stopBrowsing + cancel timer.
            case leaveTapped

            /// Tap "Close" sheet — leave + dismiss.
            case closeTapped
        }

        // MARK: - Delegate (dla parenta — AppTabNewFeature)

        case delegate(Delegate)

        enum Delegate {
            /// Sheet zamknięty, parent może wyczyścić destination.
            case didDismiss
        }
    }
}
