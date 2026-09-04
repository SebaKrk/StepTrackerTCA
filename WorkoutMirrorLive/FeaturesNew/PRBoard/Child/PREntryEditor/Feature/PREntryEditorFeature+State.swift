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

        /// Raw weight input as typed — parsed on save (`parsedScore`), never mid-typing.
        var weightText: String = ""

        /// Raw rep-count input (`scoreType == reps`).
        var repsText: String = ""

        /// AMRAP completed-rounds stepper (`scoreType == amrap`).
        var amrapRounds: Int = 0

        /// AMRAP extra-reps stepper (`scoreType == amrap`).
        var amrapExtraReps: Int = 0

        /// For Time minutes wheel (`scoreType == time`).
        var timeMinutes: Int = 0

        /// For Time seconds wheel (`scoreType == time`).
        var timeSeconds: Int = 0

        /// Rx (true) / scaled (false) — rendered only when the movement supports the split.
        var isRx: Bool = true

        /// What was scaled — asked only while Scaled is selected; empty persists as nil.
        var scalingNoteText: String = ""

        /// Circumstances of the attempt (FR-004); nil until the user declares one.
        var context: PRContext?

        /// Multi-select equipment used for the attempt.
        var equipment: Set<PREquipment> = []

        /// Rate of perceived exertion (6.0–10.0 in 0.5 steps); nil = not reported.
        var rpe: Double?

        /// Free-form note; empty string persists as nil.
        var note: String = ""

        // MARK: - Presentation

        /// Save-failure alert; while non-nil the sheet stays open (no dismiss on error).
        @Presents var alert: AlertState<Action.Alert>?

        // MARK: - Validation

        /// Accepts both dot and comma decimal separators; nil or ≤ 0 disables Save.
        var parsedWeight: Double? {
            guard let value = Double(weightText.replacingOccurrences(of: ",", with: ".")), value > 0 else {
                return nil
            }
            return value
        }

        /// Score built from the type-specific inputs; nil (empty/invalid) disables Save.
        var parsedScore: PRScoreValue? {
            switch movement.scoreType {
            case .weight:
                guard let kilograms = parsedWeight else { return nil }
                return .weight(kilograms: kilograms)
            case .time:
                let seconds = timeMinutes * 60 + timeSeconds
                guard seconds > 0 else { return nil }
                return .time(seconds: seconds)
            case .reps:
                guard let count = Int(repsText), count > 0 else { return nil }
                return .reps(count: count)
            case .amrap:
                guard amrapRounds + amrapExtraReps > 0 else { return nil }
                return .amrap(rounds: amrapRounds, extraReps: amrapExtraReps)
            }
        }

        var isSaveDisabled: Bool { parsedScore == nil }

        // MARK: - Init

        init(movement: PRMovement, now: Date) {
            self.movement = movement
            self.maxDate = now
            self.date = now
        }
    }
}
