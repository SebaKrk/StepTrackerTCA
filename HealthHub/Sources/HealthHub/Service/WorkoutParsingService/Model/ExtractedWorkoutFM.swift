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

    @Guide(description: "Workout name")
    var name: String

    @Guide(description: "Workout date (yyyy-MM-dd)")
    var date: String

    @Guide(description: "Total duration in minutes (typically 55-60 min for full workout)", .range(40...90))
    var totalEstimatedMinutes: Int

    @Guide(description: "Workout sections", .count(1...20))
    var sections: [WorkoutSectionFM]  // ← LAST (complex property, generates better when last)
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

    @Guide(description: "Section name from text (e.g. 'Snatch', 'AMRAP 10'). Nil for warmup/cooldown/transition")
    var name: String?

    @Guide(description: "Exercises in this section. Required for strength/conditioning. Generate for warmup. Nil for transition and cooldown")
    var exercises: [ExerciseFM]?

    @Guide(description: "Time cap for conditioning (e.g. AMRAP 10' → 10)", .range(1...120))
    var timeCapMinutes: Int?

    @Guide(description: "Round scheme: 'AMRAP', '5 rounds', 'FOR TIME'")
    var rounds: String?

    @Guide(description: "Duration for warmup/transition/cooldown", .range(1...120))
    var durationMinutes: Int?

    @Guide(description: "Section description")
    var description: String?

    @Guide(description: "Additional notes")
    var notes: String?
}

// MARK: - ExerciseFM

@available(iOS 26.0, *)
@Generable
struct ExerciseFM {

    @Guide(description: "Exercise name from vocabulary (e.g. 'Snatch', 'American Swing', 'HSPU'). NOT section name!")
    var name: String

    @Guide(description: "Total reps for conditioning (e.g. '16 SWING' → 16). Nil for strength with set schemes", .range(1...1000))
    var reps: Int?

    @Guide(description: "Set schemes for strength (e.g. '4x5' → [{setNumber:4, reps:5}])")
    var sets: [ExerciseSetFM]?

    @Guide(description: "Weight options (e.g. '24/16, 28/20, 32/24')")
    var scalingOptions: String?
}

// MARK: - ExerciseSetFM

@available(iOS 26.0, *)
@Generable
struct ExerciseSetFM {

    @Guide(description: "Number of sets (e.g. '4x5' → 4)", .range(1...100))
    var setNumber: Int

    @Guide(description: "Reps per set (e.g. '4x5' → 5)", .range(1...1000))
    var reps: Int

    @Guide(description: "Intensity from text (e.g. '50-60%', '80kg', 'RX')")
    var intensity: String?

    @Guide(description: "Rest between sets in seconds")
    var restSeconds: Int?
}

#endif
