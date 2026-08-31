//
//  PRCatalog.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 31/08/2026.
//

import Foundation

/// Static PR Board catalog — single source of truth for the core movement set.
/// Compiled-in data by design (see PRD FR-002); extending the set is a code change.
public enum PRCatalog {

    public static let movements: [PRMovement] = [
        // MARK: Olympic
        PRMovement(id: "snatch", name: "Snatch", category: .olympic, subgroup: .snatchFamily, scoreType: .weight, exerciseType: .snatch),
        PRMovement(id: "power-snatch", name: "Power Snatch", category: .olympic, subgroup: .snatchFamily, scoreType: .weight, exerciseType: .powerSnatch),
        PRMovement(id: "clean-and-jerk", name: "Clean & Jerk", category: .olympic, subgroup: .cleanFamily, scoreType: .weight, exerciseType: .cleanAndJerk),
        PRMovement(id: "clean", name: "Clean", category: .olympic, subgroup: .cleanFamily, scoreType: .weight, exerciseType: .squatClean),
        PRMovement(id: "power-clean", name: "Power Clean", category: .olympic, subgroup: .cleanFamily, scoreType: .weight, exerciseType: .powerClean),

        // MARK: Strength
        PRMovement(id: "back-squat", name: "Back Squat", category: .strength, subgroup: .squats, scoreType: .weight, exerciseType: .backSquat),
        PRMovement(id: "front-squat", name: "Front Squat", category: .strength, subgroup: .squats, scoreType: .weight, exerciseType: .frontSquat),
        PRMovement(id: "overhead-squat", name: "Overhead Squat", category: .strength, subgroup: .squats, scoreType: .weight, exerciseType: .overheadSquat),
        PRMovement(id: "deadlift", name: "Deadlift", category: .strength, subgroup: .pulls, scoreType: .weight, exerciseType: .deadlift),
        // Sumo maps to .deadlift — catalog v6 treats sumo as an alias of deadlift.
        PRMovement(id: "sumo-deadlift", name: "Sumo Deadlift", category: .strength, subgroup: .pulls, scoreType: .weight, exerciseType: .deadlift),
        PRMovement(id: "strict-press", name: "Strict Press", category: .strength, subgroup: .presses, scoreType: .weight, exerciseType: .shoulderPress),
        PRMovement(id: "push-press", name: "Push Press", category: .strength, subgroup: .presses, scoreType: .weight, exerciseType: .pushPress),
        PRMovement(id: "bench-press", name: "Bench Press", category: .strength, subgroup: .presses, scoreType: .weight, exerciseType: .benchPress),

        // MARK: Gymnastics
        PRMovement(id: "pull-up", name: "Pull-up", category: .gymnastics, subgroup: .barGymnastics, scoreType: .reps, exerciseType: .pullUps),
        PRMovement(id: "chest-to-bar-pull-up", name: "Chest-to-Bar Pull-up", category: .gymnastics, subgroup: .barGymnastics, scoreType: .reps),
        PRMovement(id: "toes-to-bar", name: "Toes-to-Bar", category: .gymnastics, subgroup: .barGymnastics, scoreType: .reps, exerciseType: .toesToBar),
        PRMovement(id: "muscle-up", name: "Muscle-up", category: .gymnastics, subgroup: .barGymnastics, scoreType: .reps, exerciseType: .ringMuscleUps),
        PRMovement(id: "handstand-push-up", name: "Handstand Push-up", category: .gymnastics, subgroup: .handstand, scoreType: .reps, exerciseType: .handstandPushUps),

        // MARK: Conditioning
        PRMovement(id: "row-500m", name: "Row 500 m", category: .conditioning, subgroup: .rowing, scoreType: .time, exerciseType: .rowing),
        PRMovement(id: "row-2000m", name: "Row 2000 m", category: .conditioning, subgroup: .rowing, scoreType: .time, exerciseType: .rowing),
        PRMovement(id: "run-1km", name: "Run 1 km", category: .conditioning, subgroup: .running, scoreType: .time, exerciseType: .running),
        PRMovement(id: "run-5km", name: "Run 5 km", category: .conditioning, subgroup: .running, scoreType: .time, exerciseType: .running),
        PRMovement(id: "bike-erg-1000m", name: "Bike Erg 1000 m", category: .conditioning, subgroup: .cycling, scoreType: .time, exerciseType: .cycling),

        // MARK: Benchmarks
        PRMovement(id: "fran", name: "Fran", category: .benchmarks, subgroup: .girls, scoreType: .time, supportsRxScaled: true, rxStandard: "21-15-9 · thrusters 42.5/30 kg · pull-ups", wodAliases: ["fran"]),
        PRMovement(id: "grace", name: "Grace", category: .benchmarks, subgroup: .girls, scoreType: .time, supportsRxScaled: true, rxStandard: "30 clean & jerks for time · 61/43 kg", wodAliases: ["grace"]),
        PRMovement(id: "helen", name: "Helen", category: .benchmarks, subgroup: .girls, scoreType: .time, supportsRxScaled: true, rxStandard: "3 RFT · 400 m run · 21 KB swings 24/16 kg · 12 pull-ups", wodAliases: ["helen"]),
        PRMovement(id: "diane", name: "Diane", category: .benchmarks, subgroup: .girls, scoreType: .time, supportsRxScaled: true, rxStandard: "21-15-9 · deadlifts 102/70 kg · handstand push-ups", wodAliases: ["diane"]),
        PRMovement(id: "cindy", name: "Cindy", category: .benchmarks, subgroup: .girls, scoreType: .amrap, supportsRxScaled: true, rxStandard: "AMRAP 20 min · 5 pull-ups · 10 push-ups · 15 air squats", wodAliases: ["cindy"]),
        PRMovement(id: "murph", name: "Murph", category: .benchmarks, subgroup: .heroes, scoreType: .time, supportsRxScaled: true, rxStandard: "For time · 1 mile run · 100 pull-ups · 200 push-ups · 300 air squats · 1 mile run · vest 9/6 kg", wodAliases: ["murph", "memorial day murph"]),
    ]

    /// Movements of one category in declaration order (stable for sectioned lists).
    public static func movements(in category: PRCategory) -> [PRMovement] {
        movements.filter { $0.category == category }
    }

    public static func movement(id: String) -> PRMovement? {
        movements.first { $0.id == id }
    }
}
