//
//  GymRoomFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 23/05/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

extension GymRoomFeature {

    @ObservableState
    struct State {

        /// Czy klasa jest aktywna (advertising w sieci lokalnej, kafelki widoczne).
        var isLive: Bool = false

        /// Lista podłączonych athletów. Klucz = `deviceID` (per-install UUID peer'a).
        var athletes: IdentifiedArrayOf<AthleteTile> = []
    }

    /// Pojedynczy kafelek athlety w grid.
    ///
    /// `id` = `deviceID` (= `HRSamplePayload.deviceID`). Stabilny per-install,
    /// niezależny od `CBPeripheral.identifier` (rotujący per BLE cycle) — pozwala
    /// rozpoznać że "ten sam peer wrócił" po disconnect/reconnect.
    /// `nick` jest tylko display name (może się powtarzać między peerami).
    struct AthleteTile: Identifiable, Sendable, Equatable {
        let id: UUID
        let nick: String
        var bpm: Int = 0
        var maxHR: Int = 190
        var activeEnergy: Double = 0

        /// %HR obliczone z bpm / maxHR. Bezpieczne na maxHR = 0.
        var percentHR: Int {
            guard maxHR > 0 else { return 0 }
            return Int((Double(bpm) / Double(maxHR)) * 100)
        }

        /// Aktualna strefa HR — używana do gradient background + color tilea.
        var zone: HeartRateZone {
            let value = Double(percentHR) / 100
            return HeartRateZone.allCases.first { $0.percentageRange.contains(value) } ?? .resting
        }
    }
}
