//
//  JoinLiveClassFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 23/05/2026.
//

import ComposableArchitecture
import Foundation

extension JoinLiveClassFeature {

    @ObservableState
    struct State {

        /// Nick athlety. Persystowany w AppStorage, default = "Athlete-XXX".
        /// Klucz w camelCase (KVO nie pozwala na kropki) — TODO: przenieść do `AppStorageKeys`.
        @Shared(.appStorage("joinLiveClassNick"))
        var nick: String = "Athlete-\(Int.random(in: 100...999))"

        /// Stabilny userID per zainstalowanie. Generowany raz, persystowany.
        @Shared(.appStorage("joinLiveClassUserID"))
        var userIDString: String = UUID().uuidString

        /// Aktualna faza UI.
        var phase: Phase = .idle
    }

    enum Phase: Equatable, Sendable {
        case idle
        case searching
        case connected
    }
}
