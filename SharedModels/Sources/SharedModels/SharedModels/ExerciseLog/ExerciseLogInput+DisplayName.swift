//
//  ExerciseLogInput+DisplayName.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 10/05/2026.
//

import Foundation

public extension ExerciseLogInput {

    /// Display name preferring the matched `ExerciseType.displayName`,
    /// falling back to `unmatchedName` (raw OCR / AI input) when the type is `.unknown`,
    /// and finally to the `.unknown` displayName ("Unknown Exercise") if neither has a usable value.
    ///
    /// Use this in any UI rendering of an `ExerciseLogInput` — keeps the fallback chain
    /// consistent across Summary screen, edit sheets, and post-workout result tables.
    var displayName: String {
        if let type = exerciseType, type != .unknown {
            return type.displayName
        }
        if let custom = unmatchedName, !custom.isEmpty {
            return custom
        }
        return exerciseType?.displayName ?? "—"
    }

    /// True when no `ExerciseType` was matched (`nil` or `.unknown`) — the displayed name
    /// comes from `unmatchedName` (raw OCR/AI input), not from the catalog.
    /// Use this to surface a "missing from catalog" indicator (badge / star) in dev,
    /// so developers can see which exercise types still need to be added to `ExerciseType`.
    var isUnmatched: Bool {
        exerciseType == nil || exerciseType == .unknown
    }
}
