//
//  ExerciseType.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 07/07/2025.
//


import Foundation

// MARK: - Exercise Type
public enum ExerciseType: String, CaseIterable, Sendable {
    // Strength/Weightlifting (z obciążeniem)
    case deadlift
    case backSquat
    case frontSquat
    case benchPress
    case shoulderPress
    case overheadSquat
    
    // Olympic Weightlifting
    case snatch
    case cleanAndJerk
    case powerClean
    case powerSnatch
    
    case hangPowerClean
    case hangPowerSnatch
    
    // CrossFit/Cardio (bodyweight + tempo)
    case pullUps
    case pushUps
    case burpees
    case airSquat
    case boxJumps
    case doubleUnders
    case toesToBar
    case sitUps
    
    // Fitness/Cardio
    case running
    case rowing
    case cycling
    case swimming
    
    // Kettlebell
    case kettlebellSwing
    case kettlebellClean
    case kettlebellSnatch
    case kettlebellPushPress
    case turkishGetUp
    
    // Gymnastics
    case handstandPushUps
    case barMuscleUps
    case ringMuscleUps
    case pistolSquats
    case handstandWalk
    case ringDips
    case ropeClimb
    
    // Other
    case lunges

    public var displayName: String {
        switch self {
        case .deadlift: return "Deadlift"
        case .backSquat: return "Back Squat"
        case .frontSquat: return "Front Squat"
        case .benchPress: return "Bench Press"
        case .shoulderPress: return "Shoulder Press"
        case .overheadSquat: return "Overhead Squat"
        case .snatch: return "Snatch"
        case .cleanAndJerk: return "Clean and Jerk"
        case .powerClean: return "Power Clean"
        case .powerSnatch: return "Power Snatch"
        case .hangPowerClean: return "Hang Power Clean"
        case .hangPowerSnatch: return "Hang Power Snatch"
        case .pullUps: return "Pull-ups"
        case .pushUps: return "Push-ups"
        case .burpees: return "Burpees"
        case .airSquat: return "Air Squat"
        case .boxJumps: return "Box Jumps"
        case .doubleUnders: return "Double Unders"
        case .toesToBar: return "Toes to Bar"
        case .sitUps: return "Sit-ups"
        case .running: return "Running"
        case .rowing: return "Rowing"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .kettlebellSwing: return "Kettlebell Swing"
        case .kettlebellClean: return "Kettlebell Clean"
        case .kettlebellSnatch: return "Kettlebell Snatch"
        case .kettlebellPushPress: return "Kettlebell Push Press"
        case .turkishGetUp: return "Turkish Get-up"
        case .handstandPushUps: return "Handstand Push-ups"
        case .barMuscleUps: return "Bar Muscle-ups"
        case .ringMuscleUps: return "Ring Muscle-ups"
        case .pistolSquats: return "Pistol Squats"
        case .handstandWalk: return "Handstand Walk"
        case .ringDips: return "Ring Dips"
        case .ropeClimb: return "Rope Climb"
        case .lunges: return "Lunges"
        }
    }
    
    public var aliases: [String] {
        switch self {
        case .deadlift:
            return ["deadlift", "dead lift", "DL"]
        case .backSquat:
            return ["back squat", "squat", "BS"]
        case .frontSquat:
            return ["front squat", "front squats", "FS"]
        case .benchPress:
            return ["bench press", "bench", "BP"]
        case .shoulderPress:
            return ["shoulder press", "strict press", "military press", "DB shoulder press", "dumbbell shoulder press", "press"]
        case .overheadSquat:
            return ["overhead squat", "OHS"]
        case .snatch:
            return ["snatch", "full snatch", "squat snatch"]
        case .cleanAndJerk:
            return ["clean and jerk", "clean & jerk", "C&J", "CJ", "hang clean and jerk", "hang clean & jerk", "hang clean jerk"]
        case .powerClean:
            return ["power clean", "PC"]
        case .powerSnatch:
            return ["power snatch", "PS"]
        case .hangPowerClean:
            return ["power clean", "PC", "HPC", "hang PC", "hang power clean"]
        case .hangPowerSnatch:
            return ["power snatch", "PS", "HPS", "hang PS", "hang power snatch"]
        case .pullUps:
            return ["pull-ups", "pull ups", "PU"]
        case .pushUps:
            return ["push-ups", "push ups", "pushups"]
        case .burpees:
            return ["burpees", "burpee", "burpee box jump", "burpee box jump over", "burpee over box"]
        case .airSquat:
            return ["air squat", "bodyweight squat", "air squats"]
        case .boxJumps:
            return ["box jumps", "box jump", "BJ", "BOB", "box", "box jump-overs", "box jump overs", "box jump over", "jump-overs"]
        case .doubleUnders:
            return ["double unders", "double-unders", "DU"]
        case .toesToBar:
            return ["toes to bar", "toes-to-bar", "T2B"]
        case .sitUps:
            return ["sit up", "sit-up", "situp"]
        case .running:
            return ["running", "run", "jog", "meter run", "m run", "km run", "mile run"]
        case .rowing:
            return ["rowing", "row", "erg"]
        case .cycling:
            return ["cycling", "bike", "bicycle"]
        case .swimming:
            return ["swimming", "swim"]
        case .kettlebellSwing:
            return ["kettlebell swing", "KB swing", "american swing", "russian swing"]
        case .kettlebellClean:
            return ["kettlebell clean", "KB clean"]
        case .kettlebellSnatch:
            return ["kettlebell snatch", "KB snatch"]
        case .kettlebellPushPress:
            return ["kettlebell push press", "KB push press", "KTB push press", "KB/DB push press", "DB push press", "dumbbell push press"]
        case .turkishGetUp:
            return ["turkish get-up", "turkish getup", "TGU"]
        case .handstandPushUps:
            return ["handstand push-ups", "handstand pushups", "HSPU"]
        case .barMuscleUps:
            return ["bar muscle-ups", "bar muscle ups", "BMU", "pull-up bar muscle-ups"]
        case .ringMuscleUps:
            return ["ring muscle-ups", "ring muscle ups", "RMU", "gymnastic rings muscle-ups"]
        case .pistolSquats:
            return ["pistol squats", "pistol squat", "single leg squat"]
        case .handstandWalk:
            return ["handstand walk", "HS walk", "HSWALK"]
        case .ringDips:
            return ["ring dips", "gymnastic ring dips"]
        case .ropeClimb:
            return ["rope climb", "rope climbing", "climb rope"]
        case .lunges:
            return ["lunges", "lunge", "walking lunges", "reverse lunges", "goblet lunges", "goblet reverse lunges"]
        }
    }
    
    public var category: WorkoutCategoryNew {
        switch self {
        case .deadlift, .backSquat, .frontSquat, .benchPress, .shoulderPress, .overheadSquat:
            return .strength
        case .snatch, .cleanAndJerk, .powerClean, .powerSnatch, .hangPowerClean, .hangPowerSnatch:
            return .weightlifting
        case .pullUps, .pushUps, .burpees, .airSquat, .boxJumps, .doubleUnders, .toesToBar, .sitUps:
            return .crossfit
        case .running, .rowing, .cycling, .swimming:
            return .cardio
        case .kettlebellSwing, .kettlebellClean, .kettlebellSnatch, .kettlebellPushPress, .turkishGetUp:
            return .kettlebell
        case .handstandPushUps, .barMuscleUps, .ringMuscleUps, .pistolSquats, .handstandWalk, .ringDips, .ropeClimb:
            return .gymnastics
        case .lunges:
            return .other
        }
    }
}

// MARK: - Workout Category
public enum WorkoutCategoryNew: Sendable {
    case strength
    case weightlifting
    case crossfit
    case cardio
    case kettlebell
    case gymnastics
    case other

    public var displayName: String {
        switch self {
        case .strength: return "Strength"
        case .weightlifting: return "Weightlifting"
        case .crossfit: return "CrossFit"
        case .cardio: return "Cardio"
        case .kettlebell: return "Kettlebell"
        case .gymnastics: return "Gymnastics"
        case .other: return "Other"
        }
    }
}
