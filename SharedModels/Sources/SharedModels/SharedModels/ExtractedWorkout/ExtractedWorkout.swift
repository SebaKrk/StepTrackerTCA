//
//  ExtractedWorkout.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 11/02/2026.
//

import Foundation

// MARK: - ExtractedWorkout

/// A structured workout extracted from OCR text, enriched by Foundation Models.
///
/// Contains the parsed workout sections (warmup, strength, conditioning, etc.)
/// along with AI-generated metadata like workout name, estimated duration,
/// and the original raw OCR text for user editing.
public struct ExtractedWorkout: Sendable, Equatable, Codable {
    public let name: String
    public let date: String
    public let totalEstimatedMinutes: Int
    public let rawText: String
    public let sections: [WorkoutSection]

    public init(
        name: String,
        date: String,
        totalEstimatedMinutes: Int,
        rawText: String,
        sections: [WorkoutSection]
    ) {
        self.name = name
        self.date = date
        self.totalEstimatedMinutes = totalEstimatedMinutes
        self.rawText = rawText
        self.sections = sections
    }
}

// MARK: - SectionType

/// The type of a workout section.
public enum SectionType: String, Sendable, Equatable, Codable {
    case warmup
    case strength
    case conditioning
    case transition
    case cooldown
}

// MARK: - WorkoutSection

/// A single section within an extracted workout.
public struct WorkoutSection: Sendable, Equatable, Codable {
    public let type: SectionType
    public let name: String?
    public let durationMinutes: Int?
    public let description: String?
    public let timeCapMinutes: Int?
    public let rounds: String?
    public let exercises: [ExtractedExercise]?
    public let notes: String?

    public init(
        type: SectionType,
        name: String? = nil,
        durationMinutes: Int? = nil,
        description: String? = nil,
        timeCapMinutes: Int? = nil,
        rounds: String? = nil,
        exercises: [ExtractedExercise]? = nil,
        notes: String? = nil
    ) {
        self.type = type
        self.name = name
        self.durationMinutes = durationMinutes
        self.description = description
        self.timeCapMinutes = timeCapMinutes
        self.rounds = rounds
        self.exercises = exercises
        self.notes = notes
    }
}

// MARK: - ExtractedExercise

/// An exercise extracted from OCR text.
public struct ExtractedExercise: Sendable, Equatable, Codable {
    public let name: String
    public let reps: Int?
    public let sets: [ExerciseSet]?
    public let scalingOptions: String?

    public init(
        name: String,
        reps: Int? = nil,
        sets: [ExerciseSet]? = nil,
        scalingOptions: String? = nil
    ) {
        self.name = name
        self.reps = reps
        self.sets = sets
        self.scalingOptions = scalingOptions
    }
}

// MARK: - ExerciseSet

/// A single set within an exercise, with optional intensity and rest info.
public struct ExerciseSet: Sendable, Equatable, Codable {
    public let setNumber: Int
    public let reps: Int
    public let intensity: String?
    public let restSeconds: Int?

    public init(
        setNumber: Int,
        reps: Int,
        intensity: String? = nil,
        restSeconds: Int? = nil
    ) {
        self.setNumber = setNumber
        self.reps = reps
        self.intensity = intensity
        self.restSeconds = restSeconds
    }
}
