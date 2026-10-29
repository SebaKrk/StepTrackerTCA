//
//  ClaudeWorkoutOutputSchema.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 29/10/2026.
//

import Foundation

/// JSON schema of `ExtractedWorkout`, enforced server-side through structured outputs.
///
/// Every key is required and unknown values are `null`, so the model never omits a
/// field and the decoder never meets a missing key. Enums are enforced for section
/// type, workout type and units; `rounds` stays a string because its closed list
/// carries numbers ("Tabata 8", "3 rounds for time") that enums cannot express.
enum ClaudeWorkoutOutputSchema {

    static let schema: JSONValue = [
        "type": "object",
        "additionalProperties": false,
        "required": ["name", "date", "workoutType", "totalEstimatedMinutes", "sections"],
        "properties": [
            "name": ["type": "string", "description": "Workout name"],
            "date": nullable("string", "yyyy-MM-dd when written on the board, otherwise null"),
            "workoutType": [
                "type": "string",
                "enum": ["running", "walking", "cycling", "swimming", "crossTraining",
                         "functional", "endurance", "boxing", "strengthTraining"],
            ],
            "totalEstimatedMinutes": ["type": "integer", "description": "Sum of all durationMinutes"],
            "sections": ["type": "array", "items": section],
        ],
    ]

    private static let section: JSONValue = [
        "type": "object",
        "additionalProperties": false,
        "required": ["type", "name", "durationMinutes", "description", "timeCapMinutes",
                     "rounds", "exercises", "notes"],
        "properties": [
            "type": [
                "type": "string",
                "enum": ["warmup", "strength", "conditioning", "mobility", "transition", "cooldown"],
            ],
            "name": nullable("string", "What the athlete works on, never the format"),
            "durationMinutes": ["type": "integer", "description": "Minutes the block takes in the class"],
            "description": nullable("string", "Free text of a warmup / cooldown / transition"),
            "timeCapMinutes": nullable("integer", "Cap of a timed WOD"),
            "rounds": nullable("string", "null, AMRAP, EMOM, Tabata N, For time or N rounds for time"),
            "exercises": ["anyOf": [["type": "array", "items": exercise], ["type": "null"]]],
            "notes": nullable("string", "Rest between rounds, interval, class budget remarks"),
        ],
    ]

    private static let exercise: JSONValue = [
        "type": "object",
        "additionalProperties": false,
        "required": ["name", "reps", "unit", "sets", "scalingOptions"],
        "properties": [
            "name": ["type": "string"],
            "reps": nullable("integer", "Reps, meters, seconds… per the unit; null when sets[] carries them"),
            "unit": ["anyOf": [
                ["type": "string", "enum": ["reps", "seconds", "minutes", "meters", "calories", "laps"]],
                ["type": "null"],
            ]],
            "sets": ["anyOf": [["type": "array", "items": exerciseSet], ["type": "null"]]],
            "scalingOptions": nullable("string", "Loads, rest, alternatives and ranges"),
        ],
    ]

    private static let exerciseSet: JSONValue = [
        "type": "object",
        "additionalProperties": false,
        "required": ["setNumber", "reps", "intensity", "restSeconds"],
        "properties": [
            "setNumber": ["type": "integer"],
            "reps": nullable("integer", "Reps of this set"),
            "intensity": nullable("string", "Load or percentage, e.g. 80kg, 70%"),
            "restSeconds": nullable("integer", "Rest after this set"),
        ],
    ]

    private static func nullable(_ type: JSONValue, _ description: JSONValue) -> JSONValue {
        ["type": [type, "null"], "description": description]
    }
}
