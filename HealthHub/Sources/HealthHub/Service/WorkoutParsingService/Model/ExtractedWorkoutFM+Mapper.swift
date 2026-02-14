//
//  ExtractedWorkoutFM+Mapper.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 11/02/2026.
//

import Foundation
import SharedModels

#if canImport(FoundationModels)

// MARK: - ExtractedWorkoutFM → ExtractedWorkout

@available(iOS 26.0, *)
extension ExtractedWorkoutFM {

    func toExtractedWorkout(rawText: String) -> ExtractedWorkout {
        ExtractedWorkout(
            name: name,
            date: date,
            totalEstimatedMinutes: totalEstimatedMinutes,
            rawText: rawText,
            sections: sections.map { $0.toWorkoutSection() }
        )
    }
}

// MARK: - WorkoutSectionFM → WorkoutSection

@available(iOS 26.0, *)
extension WorkoutSectionFM {

    func toWorkoutSection() -> WorkoutSection {
        // CRITICAL: Remove exercises from transition/cooldown (FM may generate despite instructions)
        let validExercises: [ExtractedExercise]?
        if type == .transition || type == .cooldown {
            validExercises = nil
        } else {
            validExercises = exercises?.map { $0.toExtractedExercise() }
        }

        return WorkoutSection(
            type: type.toSectionType(),
            name: name,
            durationMinutes: durationMinutes,
            description: description,
            timeCapMinutes: timeCapMinutes,
            rounds: rounds,
            exercises: validExercises,  // ← Filtered
            notes: notes
        )
    }
}

// MARK: - SectionTypeFM → SectionType

@available(iOS 26.0, *)
extension SectionTypeFM {

    func toSectionType() -> SectionType {
        switch self {
        case .warmup: .warmup
        case .strength: .strength
        case .conditioning: .conditioning
        case .transition: .transition
        case .cooldown: .cooldown
        }
    }
}

// MARK: - ExerciseFM → ExtractedExercise

@available(iOS 26.0, *)
extension ExerciseFM {

    func toExtractedExercise() -> ExtractedExercise {
        ExtractedExercise(
            name: name,
            reps: reps,
            sets: sets?.map { $0.toExerciseSet() },
            scalingOptions: scalingOptions
        )
    }
}

// MARK: - ExerciseSetFM → ExerciseSet

@available(iOS 26.0, *)
extension ExerciseSetFM {

    func toExerciseSet() -> ExerciseSet {
        ExerciseSet(
            setNumber: setNumber,
            reps: reps,
            intensity: intensity,
            restSeconds: restSeconds
        )
    }
}

#endif
