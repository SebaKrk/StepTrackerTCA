//
//  PREntryEditorFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 01/09/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

extension PREntryEditorFeature {

    @ObservableState
    struct State: Equatable {

        // MARK: - Properties

        /// Catalog movement the new entry belongs to (drives Rx/scaled visibility).
        let movement: PRMovement

        /// Upper bound of the date picker — injected by the parent from `\.date.now`
        /// so the reducer stays free of uncontrolled dependencies.
        let maxDate: Date

        // MARK: - Draft

        /// User-chosen day of the result; defaults to today, capped at `maxDate`.
        var date: Date

        /// Raw weight input as typed — parsed on save (`parsedWeight`), never mid-typing.
        var weightText: String = ""

        /// Rx (true) / scaled (false) — rendered only when the movement supports the split.
        var isRx: Bool = true

        /// Circumstances of the attempt (FR-004); defaults to a fresh attempt.
        var context: PRContext = .fresh

        /// Multi-select equipment used for the attempt.
        var equipment: Set<PREquipment> = []

        /// Rate of perceived exertion (6.0–10.0 in 0.5 steps); nil = not reported.
        var rpe: Double?

        /// Free-form note; empty string persists as nil.
        var note: String = ""

        // MARK: - Validation

        /// Accepts both dot and comma decimal separators; nil or ≤ 0 disables Save.
        var parsedWeight: Double? {
            guard let value = Double(weightText.replacingOccurrences(of: ",", with: ".")), value > 0 else {
                return nil
            }
            return value
        }

        var isSaveDisabled: Bool { parsedWeight == nil }

        // MARK: - Init

        init(movement: PRMovement, now: Date) {
            self.movement = movement
            self.maxDate = now
            self.date = now
        }
    }
}
