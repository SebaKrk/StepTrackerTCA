//
//  GymRoomFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 23/05/2026.
//

import ComposableArchitecture
import Foundation

extension GymRoomFeature {

    @ObservableState
    struct State {

        /// Czy klasa jest aktywna (advertising w sieci lokalnej, kafelki widoczne).
        var isLive: Bool = false

        /// Lista podłączonych athletów. Klucz = nick (= `MCPeerID.displayName`).
        var athletes: IdentifiedArrayOf<AthleteTile> = []
    }

    /// Pojedynczy kafelek athlety w grid.
    ///
    /// `id` = nick = `MCPeerID.displayName`. Stabilny identyfikator dla całej sesji,
    /// używany do match'owania peer events i HR samples (które też niosą nick).
    struct AthleteTile: Identifiable, Sendable, Equatable {
        let id: String
        var bpm: Int = 0
        var maxHR: Int = 190

        /// %HR obliczone z bpm / maxHR. Bezpieczne na maxHR = 0.
        var percentHR: Int {
            guard maxHR > 0 else { return 0 }
            return Int((Double(bpm) / Double(maxHR)) * 100)
        }
    }
}
