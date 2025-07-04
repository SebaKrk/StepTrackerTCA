//
//  TrainingSessionAI.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 30/06/2025.
//

import FoundationModels
import Foundation

// MARK: - Training Session AI (główny obiekt treningu)
@available(iOS 26.0, *)
@Generable
struct TrainingSessionAI {
    @Guide(description: "Parse and extract the date from the training plan or use today's date if not specified")
    let date: String
    
    @Guide(description: "Generate intelligent warm-up description based on the exercises in workouts. Include mobility work, activation exercises, and light cardio that prepare the body for the main workout. Example: For deadlifts include hip mobility and glute activation")
    let warmUp: WarmUpAI?
    
    @Guide(description: "Parse all workout sections from the training plan. Look for markers like 'A)', 'B)', numbered sections, 'EMOM', 'AMRAP', etc.")
    let workouts: [WorkoutAI]
    
    @Guide(description: "Generate cool-down description targeting muscle groups used in workouts. Include stretching, foam rolling, and recovery activities. Example: After upper body work include shoulder and chest stretches")
    let coolDown: CoolDownAI?
}

// MARK: - Warm Up AI
@available(iOS 26.0, *)
@Generable
struct WarmUpAI {
    @Guide(description: "Generate specific warm-up based on workout exercises. Examples: 'Dynamic leg swings, hip circles, bodyweight squats for squat day' or 'Arm circles, scapular activation, ring rows for pull-up workout'")
    let description: String
}

// MARK: - Cool Down AI
@available(iOS 26.0, *)
@Generable
struct CoolDownAI {
    @Guide(description: "Generate targeted cool-down for muscles worked. Examples: 'Hip flexor stretches, foam rolling quads after squat workout' or 'Shoulder stretches, chest doorway stretch after pressing movements'")
    let description: String
}

// MARK: - Workout Structure AI
@available(iOS 26.0, *)
@Generable
struct WorkoutAI {
    @Guide(description: "Extract workout name from markers like 'EMOM 25', 'AMRAP 12', 'A) Back Squat', 'Strength Work', 'MetCon'. Keep original formatting when possible")
    let name: String
    
    @Guide(description: "Parse time limits from text like 'TC:20', 'AMRAP 12', '15 minute cap'. Set to nil for strength work without time constraints. Convert to minutes as integer")
    let timeCap: Int?
    
    @Guide(description: "Identify round structure: nil for AMRAP/EMOM/time-based, specific number for '5 rounds', '8R', '3 sets'. For progressions like '5x5' or '10-8-6' use nil and create separate exercises")
    let rounds: Int?
    
    @Guide(description: "Convert all exercises in the workout. For rep progressions like '10-8-8-6-6' create separate ExerciseAI for each set. For EMOM create separate exercise for each minute")
    let exercises: [ExerciseAI]
}

// MARK: - Exercise Structure AI
@available(iOS 26.0, *)
@Generable
struct ExerciseAI {
    @Guide(description: "Map exercise name to closest ExerciseTypeAI enum. Use aliases: 'DL'→deadlift, 'T2B'→toesToBar, 'C&J'→cleanAndJerk, 'HSPU'→handstandPushUps, 'KB'→kettlebell variants")
    let type: ExerciseTypeAI
    
    @Guide(description: "Parse targets: numbers followed by 'reps' use reps(), 'cal/calories' use calories(), 'm/meters' use meters(), 'sec/seconds' use seconds(), 'min/minutes' use minutes()")
    let target: ExerciseTargetAI?
    
    @Guide(description: "Parse weights: format like '100/65' means men:100, women:65. Single number could be universal. Examples: '80/50kg'→men:80,women:50, '20kg'→men:20,women:20, bodyweight→nil")
    let weight: WeightAI?
    
    @Guide(description: "Include contextual info: '1RM test', 'EMOM minute 1', 'Set 2 @ 70%', 'Rest 90-120s', 'Box height 20 inches', scaling options, or technique notes")
    let info: String?
}


// MARK: - Weight Structure AI
@available(iOS 26.0, *)
@Generable
struct WeightAI {
    @Guide(description: "Weight for men in kilograms. Parse from formats like '100/65' (men:100), '80kg' (universal), or 'Rx 135/95' (men:135)")
    let men: Int?
    
    @Guide(description: "Weight for women in kilograms. Parse from formats like '100/65' (women:65), '80kg' (universal), or 'Rx 135/95' (women:95)")
    let women: Int?
}


// MARK: - Exercise Target AI
@available(iOS 26.0, *)
@Generable
enum ExerciseTargetAI {
    /// Use for repetitions: '10 reps', '5 push-ups', '3 clean and jerks'
    case reps(Int)
    
    /// Use for calorie targets: '15 cal row', '50 calories bike'
    case calories(Int)
    
    /// Use for distance: '400m run', '1000 meter row', '100m sprint'
    case meters(Int)
    
    /// Use for time duration: '30 sec plank', '45 seconds work'
    case seconds(Int)
    
    /// Use for longer time durations: '2 min AMRAP', '5 minute bike'
    case minutes(Int)
    
    /// Use rarely, mainly for internal round counting
    case rounds(Int)
    
    /// Use for track/pool laps: '4 laps around track'
    case laps(Int)
    
    var displayText: String {
        switch self {
        case .reps(let count):
            return "\(count) reps"
        case .calories(let count):
            return "\(count) cal"
        case .meters(let count):
            return "\(count) m"
        case .seconds(let count):
            return "\(count) sec"
        case .minutes(let count):
            return "\(count) min"
        case .rounds(let count):
            return "\(count) rounds"
        case .laps(let count):
            return "\(count) laps"
        }
    }
}

// MARK: - Exercise Type AI
@available(iOS 26.0, *)
@Generable
enum ExerciseTypeAI: String, CaseIterable {
    // Strength/Weightlifting (z obciążeniem)
    case deadlift
    case backSquat
    case frontSquat
    case benchPress
    case overheadSquat
    
    // Olympic Weightlifting
    case snatch
    case cleanAndJerk
    case powerClean
    case powerSnatch
    
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
    
    var displayName: String {
        switch self {
        case .deadlift: return "Deadlift"
        case .backSquat: return "Back Squat"
        case .frontSquat: return "Front Squat"
        case .benchPress: return "Bench Press"
        case .overheadSquat: return "Overhead Squat"
        case .snatch: return "Snatch"
        case .cleanAndJerk: return "Clean and Jerk"
        case .powerClean: return "Power Clean"
        case .powerSnatch: return "Power Snatch"
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
    
    var aliases: [String] {
        switch self {
        case .deadlift:
            return ["deadlift", "dead lift", "DL"]
        case .backSquat:
            return ["back squat", "squat", "BS"]
        case .frontSquat:
            return ["front squat", "FS"]
        case .benchPress:
            return ["bench press", "bench", "BP"]
        case .overheadSquat:
            return ["overhead squat", "OHS"]
        case .snatch:
            return ["snatch", "full snatch", "squat snatch"]
        case .cleanAndJerk:
            return ["clean and jerk", "clean & jerk", "C&J", "CJ"]
        case .powerClean:
            return ["power clean", "PC"]
        case .powerSnatch:
            return ["power snatch", "PS"]
        case .pullUps:
            return ["pull-ups", "pull ups", "PU"]
        case .pushUps:
            return ["push-ups", "push ups", "pushups"]
        case .burpees:
            return ["burpees", "burpee"]
        case .airSquat:
            return ["air squat", "bodyweight squat", "air squats"]
        case .boxJumps:
            return ["box jumps", "box jump", "BJ"]
        case .doubleUnders:
            return ["double unders", "double-unders", "DU"]
        case .toesToBar:
            return ["toes to bar", "toes-to-bar", "T2B"]
        case .sitUps:
            return ["sit up", "sit-up", "situp"]
        case .running:
            return ["running", "run", "jog"]
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
            return ["kettlebell push press", "KB push press", "KTB push press"]
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
            return ["lunges", "lunge", "walking lunges"]
        }
    }
    
    var category: ExerciseCategory {
        switch self {
        case .deadlift, .backSquat, .frontSquat, .benchPress, .overheadSquat:
            return .strength
        case .snatch, .cleanAndJerk, .powerClean, .powerSnatch:
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

// MARK: - Exercise Category

@available(iOS 26.0, *)
@Generable
enum ExerciseCategory {
    case strength
    case weightlifting
    case crossfit
    case cardio
    case kettlebell
    case gymnastics
    case other
}

