//
//  ClaudeWorkoutResponse.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 15/02/2026.
//

import Foundation

/// Claude JSON output - intermediate format before converting to ExtractedWorkout.
public struct ClaudeWorkoutResponse: Decodable, Sendable {
    public let name: String
    public let date: String?  // Optional - Claude might return null if date not found in OCR
    public let totalEstimatedMinutes: Int
    public let sections: [ClaudeWorkoutSection]
}

public struct ClaudeWorkoutSection: Decodable, Sendable {
    public let type: String
    public let name: String?
    public let durationMinutes: Int?
    public let description: String?
    public let timeCapMinutes: Int?
    public let rounds: String?
    public let exercises: [ClaudeExercise]?
    public let notes: String?
}

public struct ClaudeExercise: Decodable, Sendable {
    public let name: String
    public let reps: Int?
    public let sets: [ClaudeExerciseSet]?
    public let scalingOptions: String?
}

public struct ClaudeExerciseSet: Decodable, Sendable {
    public let setNumber: Int
    public let reps: Int?  // Optional - Claude might return null for unknown reps (e.g., "MAX reps")
    public let intensity: String?
    public let restSeconds: Int?
}
