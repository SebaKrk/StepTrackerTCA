//
//  ExerciseSessionDraft.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 21/02/2026.
//

import Foundation

/// Mutable draft used by `ExerciseEditorFeature` to create or edit an `ExerciseSession`.
public struct ExerciseSessionDraft: Equatable, Sendable {

    /// The exercise type selected from the picker.
    public var type: ExerciseType

    /// Custom name for `.unknown` exercises (e.g. typed manually or from OCR).
    public var customName: String?

    /// Movement target — reps, meters, seconds, etc.
    public var target: ExerciseTarget?

    /// Prescribed weight split by gender.
    public var weight: WeightConfiguration?

    /// Optional notes or coaching cues.
    public var info: String?

    // MARK: - Init (create)

    public init(
        type: ExerciseType = .deadlift,
        customName: String? = nil,
        target: ExerciseTarget? = .reps(10),
        weight: WeightConfiguration? = nil,
        info: String? = nil
    ) {
        self.type = type
        self.customName = customName
        self.target = target
        self.weight = weight
        self.info = info
    }

    // MARK: - Init (edit)

    public init(exercise: ExerciseSession) {
        self.type = exercise.type
        self.customName = exercise.customName
        self.target = exercise.target
        self.weight = exercise.weight
        self.info = exercise.info
    }
}
