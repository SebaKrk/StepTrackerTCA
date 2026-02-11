//
//  ExtractedWorkoutFM.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 11/02/2026.
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels

// MARK: - ExtractedWorkoutFM

@available(iOS 26.0, *)
@Generable
struct ExtractedWorkoutFM {

    @Guide(description: "Workout name based on exercises, e.g. 'Snatch + AMRAP Conditioning'. Fallback: 'CrossFit' + date")
    var name: String

    @Guide(description: "Date from text or today's date in yyyy-MM-dd format")
    var date: String

    @Guide(description: "Total estimated duration in minutes including warmup, transitions, cooldown")
    var totalEstimatedMinutes: Int

    @Guide(description: "All sections in order: warmup, then workout sections with transitions between them, then cooldown")
    var sections: [WorkoutSectionFM]
}

// MARK: - SectionTypeFM

@available(iOS 26.0, *)
@Generable
enum SectionTypeFM: String {
    case warmup
    case strength
    case conditioning
    case transition
    case cooldown
}

// MARK: - WorkoutSectionFM

@available(iOS 26.0, *)
@Generable
struct WorkoutSectionFM {

    var type: SectionTypeFM

    @Guide(description: "Section name for strength/conditioning, e.g. 'Snatch', 'AMRAP 10'. Nil for warmup/cooldown/transition")
    var name: String?

    @Guide(description: "Duration in minutes for warmup/cooldown/transition")
    var durationMinutes: Int?

    @Guide(description: "Description for warmup/cooldown/transition — AI generated based on exercises")
    var description: String?

    @Guide(description: "Time cap in minutes for conditioning (AMRAP, FOR TIME)")
    var timeCapMinutes: Int?

    @Guide(description: "Round scheme: 'AMRAP', '5', 'FOR TIME'")
    var rounds: String?

    @Guide(description: "Exercises in this section")
    var exercises: [ExerciseFM]?

    @Guide(description: "Additional notes about the section")
    var notes: String?
}

// MARK: - ExerciseFM

@available(iOS 26.0, *)
@Generable
struct ExerciseFM {

    @Guide(description: "Exercise name, e.g. 'Snatch', 'American Kettlebell Swing', 'HSPU'")
    var name: String

    @Guide(description: "Rep count per set, e.g. 16, 8")
    var reps: Int?

    @Guide(description: "Individual sets with details — for strength work with varying intensity")
    var sets: [ExerciseSetFM]?

    @Guide(description: "Scaling options: 'RX: 24/16 kg, Scaled: 16/12 kg'")
    var scalingOptions: String?
}

// MARK: - ExerciseSetFM

@available(iOS 26.0, *)
@Generable
struct ExerciseSetFM {

    var setNumber: Int
    var reps: Int

    @Guide(description: "Intensity: '50-60%', '80kg', 'bodyweight'")
    var intensity: String?

    @Guide(description: "Rest between sets in seconds")
    var restSeconds: Int?
}

#endif
