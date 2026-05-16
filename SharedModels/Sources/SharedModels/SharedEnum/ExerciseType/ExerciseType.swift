//
//  ExerciseType.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 07/07/2025.
//


import Foundation

// MARK: - Exercise Type
public enum ExerciseType: String, CaseIterable, Codable, Sendable {
    // Strength/Weightlifting (z obciążeniem)
    case deadlift
    case backSquat
    case frontSquat
    case benchPress
    case floorPress
    case shoulderPress
    case overheadSquat
    case romanianDeadlift
    case bentOverRow
    case gobletSquat
    case bulgarianSplitSquat
    
    // Olympic Weightlifting
    case snatch
    case cleanAndJerk
    case powerClean
    case powerSnatch

    case hangPowerClean
    case hangPowerSnatch
    case hangClean
    case pushPress
    case pushJerk
    
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
    case plank
    case chinUps
    case skinTheCat
    case kneesToElbows
    case hollowHold

    // CrossFit Classics
    case wallBalls
    case thrusters
    case devilPress
    case burpeeBoxJumps
    case dumbbellSnatch
    case dumbbellClean
    case dumbbellCleanAndJerk
    case sumoDeadliftHighPull
    case mountainClimbers
    case farmersCarry

    // Cardio Machines
    case assaultBike
    case skiErg
    case singleUnders

    // Other
    case lunges
    case unknown  // Fallback for unrecognized exercises from OCR/AI parsing

    public var displayName: String {
        switch self {
        case .deadlift: return "Deadlift"
        case .backSquat: return "Back Squat"
        case .frontSquat: return "Front Squat"
        case .benchPress: return "Bench Press"
        case .floorPress: return "Floor Press"
        case .shoulderPress: return "Shoulder Press"
        case .overheadSquat: return "Overhead Squat"
        case .romanianDeadlift: return "Romanian Deadlift"
        case .bentOverRow: return "Bent Over Row"
        case .gobletSquat: return "Goblet Squat"
        case .bulgarianSplitSquat: return "Bulgarian Split Squat"
        case .snatch: return "Snatch"
        case .cleanAndJerk: return "Clean and Jerk"
        case .powerClean: return "Power Clean"
        case .powerSnatch: return "Power Snatch"
        case .hangPowerClean: return "Hang Power Clean"
        case .hangPowerSnatch: return "Hang Power Snatch"
        case .hangClean: return "Hang Clean"
        case .pushPress: return "Push Press"
        case .pushJerk: return "Push Jerk"
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
        case .plank: return "Plank"
        case .chinUps: return "Chin-Ups"
        case .skinTheCat: return "Skin The Cat"
        case .kneesToElbows: return "Knees to Elbows"
        case .hollowHold: return "Hollow Hold"
        case .wallBalls: return "Wall Balls"
        case .thrusters: return "Thrusters"
        case .devilPress: return "Devil Press"
        case .burpeeBoxJumps: return "Burpee Box Jumps"
        case .dumbbellSnatch: return "Dumbbell Snatch"
        case .dumbbellClean: return "Dumbbell Clean"
        case .dumbbellCleanAndJerk: return "Dumbbell Clean and Jerk"
        case .sumoDeadliftHighPull: return "Sumo Deadlift High Pull"
        case .mountainClimbers: return "Mountain Climbers"
        case .farmersCarry: return "Farmer's Carry"
        case .assaultBike: return "Assault Bike"
        case .skiErg: return "Ski Erg"
        case .singleUnders: return "Single Unders"
        case .lunges: return "Lunges"
        case .unknown: return "Unknown Exercise"
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
        case .romanianDeadlift:
            return ["romanian deadlift", "romanian dead lift", "RDL", "stiff leg deadlift"]
        case .bentOverRow:
            return ["bent over row", "bent-over row", "barbell row", "pendlay row", "BOR", "BB row"]
        case .gobletSquat:
            return ["goblet squat", "goblet squats", "GS", "kettlebell goblet squat", "dumbbell goblet squat", "KB goblet squat", "DB goblet squat"]
        case .bulgarianSplitSquat:
            return ["bulgarian split squat", "bulgarian split squats", "BSS", "split squat", "rear foot elevated split squat", "RFESS"]
        case .benchPress:
            return ["bench press", "bench", "BP", "close-grip bench press", "close grip bench press", "close-grip bench", "close grip bench", "CGBP", "narrow grip bench press", "narrow-grip bench press", "wide grip bench press", "wide-grip bench press", "incline bench press", "decline bench press", "DB bench press", "dumbbell bench press"]
        case .floorPress:
            return ["floor press", "floor bench press", "FP", "DB floor press", "dumbbell floor press"]
        case .shoulderPress:
            return ["shoulder press", "strict press", "military press", "DB shoulder press", "dumbbell shoulder press", "press"]
        case .overheadSquat:
            return ["overhead squat", "OHS"]
        case .snatch:
            return ["snatch", "full snatch", "squat snatch"]
        case .cleanAndJerk:
            return ["clean and jerk", "clean & jerk", "C&J", "CJ", "hang clean and jerk", "hang clean & jerk", "hang clean jerk", "hang C&J", "hang CJ"]
        case .powerClean:
            return ["power clean", "PC"]
        case .powerSnatch:
            return ["power snatch", "PS"]
        case .hangPowerClean:
            return ["power clean", "PC", "HPC", "hang PC", "hang power clean"]
        case .hangPowerSnatch:
            return ["power snatch", "PS", "HPS", "hang PS", "hang power snatch"]
        case .hangClean:
            return ["hang clean", "HC", "BB hang clean", "barbell hang clean"]
        case .pushPress:
            return ["push press", "push-press", "PP", "barbell push press", "BB push press"]
        case .pushJerk:
            return ["push jerk", "push-jerk", "PJ", "barbell push jerk"]
        case .pullUps:
            return ["pull-ups", "pull ups", "PU"]
        case .pushUps:
            return ["push-ups", "push ups", "pushups"]
        case .burpees:
            return ["burpees", "burpee"]
        case .airSquat:
            return ["air squat", "bodyweight squat", "air squats"]
        case .boxJumps:
            return ["box jumps", "box jump", "BJ", "BOB", "box", "box jump-overs", "box jump overs", "box jump over", "jump-overs"]
        case .doubleUnders:
            return ["double unders", "double-unders", "DU"]
        case .toesToBar:
            return ["toes to bar", "toes-to-bar", "T2B"]
        case .sitUps:
            return ["sit up", "sit ups", "sit-up", "sit-ups", "situp", "situps"]
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
        case .plank:
            return ["plank", "front plank", "forearm plank", "plank on arms", "plank on forearms", "plank hold"]
        case .chinUps:
            return ["chin-ups", "chin ups", "chinup", "chin-up", "chin up", "chinups"]
        case .skinTheCat:
            return ["skin the cat", "skin-the-cat", "skinthecat", "STC"]
        case .kneesToElbows:
            return ["knees to elbows", "K2E", "k2e", "KTE", "knees-to-elbows"]
        case .hollowHold:
            return ["hollow hold", "hollow body hold", "HH", "hollow position", "hollow body"]
        case .wallBalls:
            return ["wall balls", "wall ball", "WB", "wall ball shots"]
        case .thrusters:
            return ["thrusters", "thruster", "barbell thruster", "DB thruster", "dumbbell thruster"]
        case .devilPress:
            return ["devil press", "devil presses", "devils press"]
        case .burpeeBoxJumps:
            return ["burpee box jumps", "burpee box jump", "BBJ", "burpee over box", "burpee box jump over"]
        case .dumbbellSnatch:
            return ["dumbbell snatch", "DB snatch", "single arm dumbbell snatch", "DB power snatch"]
        case .dumbbellClean:
            return ["dumbbell clean", "DB clean", "dumbbell power clean", "DB power clean"]
        case .dumbbellCleanAndJerk:
            return ["dumbbell clean and jerk", "DB clean and jerk", "dumbbell C&J", "DB C&J", "dumbbell hang clean and jerk", "DB hang clean and jerk", "hang dumbbell clean and jerk"]
        case .sumoDeadliftHighPull:
            return ["sumo deadlift high pull", "SDHP", "sumo dlhp", "sumo dl high pull", "sumo deadlift hp"]
        case .mountainClimbers:
            return ["mountain climbers", "mountain climber", "MC", "mtn climbers", "running planks"]
        case .farmersCarry:
            return ["farmers carry", "farmer carry", "farmers walk", "farmer walk", "farmer's carry", "farmer's walk", "FC"]
        case .assaultBike:
            return ["assault bike", "air bike", "echo bike", "bike erg", "AB"]
        case .skiErg:
            return ["ski erg", "ski", "skierg", "skiing"]
        case .singleUnders:
            return ["single unders", "single under", "SU", "jump rope", "jumping rope", "single jump rope"]
        case .lunges:
            return ["lunges", "lunge", "walking lunges", "reverse lunges", "goblet lunges", "goblet reverse lunges"]
        case .unknown:
            return []
        }
    }

    public var category: MovementCategory {
        switch self {
        case .deadlift, .backSquat, .frontSquat, .benchPress, .floorPress, .shoulderPress, .overheadSquat,
             .romanianDeadlift, .bentOverRow, .gobletSquat, .bulgarianSplitSquat:
            return .strength
        case .snatch, .cleanAndJerk, .powerClean, .powerSnatch, .hangPowerClean, .hangPowerSnatch,
             .hangClean, .pushPress, .pushJerk, .thrusters, .sumoDeadliftHighPull:
            return .olympicLifting
        case .pullUps, .pushUps, .toesToBar, .sitUps, .handstandPushUps, .barMuscleUps, .ringMuscleUps,
             .pistolSquats, .handstandWalk, .ringDips, .ropeClimb, .plank, .chinUps, .skinTheCat,
             .kneesToElbows, .hollowHold:
            return .gymnastics
        case .running, .rowing, .cycling, .swimming, .assaultBike, .skiErg, .singleUnders:
            return .cardio
        case .burpees, .airSquat, .boxJumps, .doubleUnders, .wallBalls, .devilPress, .burpeeBoxJumps,
             .lunges, .mountainClimbers, .farmersCarry:
            return .mixed
        case .kettlebellSwing, .kettlebellClean, .kettlebellSnatch, .turkishGetUp:
            return .strength
        case .kettlebellPushPress:
            return .olympicLifting
        case .dumbbellSnatch, .dumbbellClean, .dumbbellCleanAndJerk:
            return .olympicLifting
        case .unknown:
            return .mixed
        }
    }

    /// Whether this exercise always involves load (kg).
    /// `true` means SetInputView should show a weight field even if the plan didn't specify one
    /// (e.g. Wall Balls always use a 6/9/14kg medicine ball).
    public var requiresWeight: Bool {
        switch self {
        case .wallBalls, .farmersCarry:
            return true
        default:
            return category == .strength || category == .olympicLifting
        }
    }
}
