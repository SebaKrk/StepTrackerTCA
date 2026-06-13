//
//  JoinLiveClassFeature+Action.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 23/05/2026.
//

import ComposableArchitecture
import SharedModels

extension JoinLiveClassFeature {

    @CasePathable
    enum Action: ViewAction {

        // MARK: - Internal

        /// Subskrypcja peer events stream z `peerMirrorClient`.
        case startObservingPeerEvents

        /// Peer (iPad host) connected — switch phase do `.connected`, start HR timer.
        case peerConnected

        /// Peer disconnected — stop HR stream, phase do `.idle`.
        case peerDisconnected

        /// Załadowano user profile — aktualizuje `state.nick` zgodnie z fallback chain:
        /// `nickname` → `name` → fallback (Athlete-XXX z AppStorage).
        case userProfileLoaded(UserProfile?)

        /// Host (iPad) zakończył klasę — broadcast otrzymany via BLE notify.
        /// Reducer reset full state + delegate.didLeave (toolbar icon znika).
        case classEndedReceived

        /// Workout zakończony naturalnie (Watch / iPhone-standalone end) —
        /// `workoutMetricsStream` zamknięty. Reducer reset full state + delegate.didLeave.
        /// Identical outcome do `.classEndedReceived` ale różny trigger.
        case workoutEnded

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

            /// QR scanner odebrał payload — JSON string z `QRSessionPayload`.
            /// Reducer decode'uje, zapisuje w state, zamyka scanner i auto-triggeruje BLE handshake
            /// (sam akt celowania na QR = wybór klasy, nie wymaga dodatkowego Join'a).
            case qrScanned(jsonString: String)

            /// User zamknął scanner bez scanowania (swipe-down na fullScreenCover).
            /// Reducer resetuje `isShowingScanner` — wraca do idle z Join button.
            case scannerDismissed
        }

        // MARK: - Delegate (dla parenta — SessionFeature)

        case delegate(Delegate)

        enum Delegate {
            /// User kliknął "Dołącz" lub zamknął sheet (X / swipe-down).
            /// Parent: ukryj sheet, ale ZACHOWAJ state — broadcast trwa w tle.
            case didDismiss

            /// User kliknął "Zakończ klasę" — broadcast stop.
            /// Parent: kasuj `joinLiveClass` state + ukryj sheet.
            case didLeave
        }
    }
}
