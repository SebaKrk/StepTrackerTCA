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
    case burpeeOverBar
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

    // Gymnastics / Core (catalog v2)
    case wallWalks
    case vUps
    case chestToBarPullUps
    case ghdSitUps
    case russianTwist
    case lSit
    case handstandShoulderTaps

    // Strength accessories (catalog v2)
    case gluteBridge
    case tricepsExtension
    case plateRaise
    case landmineAntiRotation

    // Mixed / Carries (catalog v2)
    case boxStepUps
    case boxStepOvers
    case overheadCarry
    case bearHugCarry

    // Olympic umbrella (catalog v2)
    case shoulderToOverhead

    // Mobility / Rehab (catalog v3)
    case catCow
    case birdDog
    case deadBug
    case childsPose
    case pelvicTilt
    case hamstringStretch
    case gluteStretch
    case spinalTwist
    case foamRolling
    case proneArmRaises
    case openBook
    case threadTheNeedle
    case thoracicExtension
    case cobraStretch
    case wallSlides
    case pigeonPose
    case couchStretch
    case ninetyNinety
    case worldsGreatestStretch
    case pvcPassThroughs
    case downwardDog

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
        case .burpeeOverBar: return "Burpee Over Bar"
        case .dumbbellSnatch: return "Dumbbell Snatch"
        case .dumbbellClean: return "Dumbbell Clean"
        case .dumbbellCleanAndJerk: return "Dumbbell Clean and Jerk"
        case .sumoDeadliftHighPull: return "Sumo Deadlift High Pull"
        case .mountainClimbers: return "Mountain Climbers"
        case .farmersCarry: return "Farmer's Carry"
        case .assaultBike: return "Assault Bike"
        case .skiErg: return "Ski Erg"
        case .singleUnders: return "Single Unders"
        case .wallWalks: return "Wall Walks"
        case .vUps: return "V-ups"
        case .chestToBarPullUps: return "Chest-to-Bar Pull-ups"
        case .ghdSitUps: return "GHD Sit-ups"
        case .russianTwist: return "Russian Twist"
        case .lSit: return "L-sit"
        case .handstandShoulderTaps: return "Handstand Shoulder Taps"
        case .gluteBridge: return "Glute Bridge"
        case .tricepsExtension: return "Triceps Extension"
        case .plateRaise: return "Plate Raise"
        case .landmineAntiRotation: return "Landmine Anti-Rotation"
        case .boxStepUps: return "Box Step-ups"
        case .boxStepOvers: return "Box Step-overs"
        case .overheadCarry: return "Overhead Carry"
        case .bearHugCarry: return "Bear Hug Carry"
        case .shoulderToOverhead: return "Shoulder to Overhead"
        case .catCow: return "Cat-Cow"
        case .birdDog: return "Bird Dog"
        case .deadBug: return "Dead Bug"
        case .childsPose: return "Child's Pose"
        case .pelvicTilt: return "Pelvic Tilt"
        case .hamstringStretch: return "Hamstring Stretch"
        case .gluteStretch: return "Glute Stretch"
        case .spinalTwist: return "Spinal Twist"
        case .foamRolling: return "Foam Rolling"
        case .proneArmRaises: return "Prone Arm Raises"
        case .openBook: return "Open Book"
        case .threadTheNeedle: return "Thread the Needle"
        case .thoracicExtension: return "Thoracic Extension"
        case .cobraStretch: return "Cobra Stretch"
        case .wallSlides: return "Wall Slides"
        case .pigeonPose: return "Pigeon Pose"
        case .couchStretch: return "Couch Stretch"
        case .ninetyNinety: return "90/90 Hip Stretch"
        case .worldsGreatestStretch: return "World's Greatest Stretch"
        case .pvcPassThroughs: return "PVC Pass-Throughs"
        case .downwardDog: return "Downward Dog"
        case .lunges: return "Lunges"
        case .unknown: return "Unknown Exercise"
        }
    }

    public var aliases: [String] {
        switch self {
        case .deadlift:
            return ["deadlift", "dead lift", "DL", "sumo deadlift", "sumo deadlifts"]
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
            return ["bench press", "bench", "BP", "close-grip bench press", "close grip bench press", "close-grip bench", "close grip bench", "CGBP", "narrow grip bench press", "narrow-grip bench press", "wide grip bench press", "wide-grip bench press", "incline bench press", "decline bench press", "DB bench press", "dumbbell bench press", "barbell bench press", "BB bench press"]
        case .floorPress:
            return ["floor press", "floor bench press", "FP", "DB floor press", "dumbbell floor press", "barbell floor press", "BB floor press"]
        case .shoulderPress:
            return ["shoulder press", "strict press", "military press", "DB shoulder press", "dumbbell shoulder press", "press", "seated overhead press", "seated shoulder press", "overhead press", "OHP"]
        case .overheadSquat:
            return ["overhead squat", "OHS"]
        case .snatch:
            return ["snatch", "snatches", "full snatch", "full snatches", "squat snatch", "squat snatches"]
        case .cleanAndJerk:
            return ["clean and jerk", "cleans and jerks", "clean & jerk", "cleans & jerks", "C&J", "C&Js", "CJ", "CJs", "hang clean and jerk", "hang cleans and jerks", "hang clean & jerk", "hang cleans & jerks", "hang clean jerk", "hang clean jerks", "hang C&J", "hang C&Js", "hang CJ", "hang CJs"]
        case .powerClean:
            return ["power clean", "power cleans", "PC", "PCs"]
        case .powerSnatch:
            return ["power snatch", "power snatches", "PS", "PSs"]
        case .hangPowerClean:
            return ["HPC", "HPCs", "hang PC", "hang PCs", "hang power clean", "hang power cleans"]
        case .hangPowerSnatch:
            return ["HPS", "HPSs", "hang PS", "hang PSs", "hang power snatch", "hang power snatches"]
        case .hangClean:
            return ["hang clean", "hang cleans", "HC", "HCs", "BB hang clean", "BB hang cleans", "barbell hang clean", "barbell hang cleans", "hang squat clean", "hang squat cleans", "hang clean squat"]
        case .pushPress:
            return ["push press", "push presses", "push-press", "push-presses", "PP", "barbell push press", "barbell push presses", "BB push press", "BB push presses"]
        case .pushJerk:
            return ["push jerk", "push jerks", "push-jerk", "push-jerks", "PJ", "PJs", "barbell push jerk", "barbell push jerks"]
        case .pullUps:
            return ["pull-ups", "pull ups", "PU"]
        case .pushUps:
            return ["push-ups", "push ups", "pushups", "tricep push-ups", "tricep push ups", "triceps push-ups", "diamond push-ups"]
        case .burpees:
            return ["burpees", "burpee"]
        case .airSquat:
            return ["air squat", "bodyweight squat", "air squats"]
        case .boxJumps:
            return ["box jumps", "box jump", "BJ", "BOB", "box", "box jump-overs", "box jump overs", "box jump over", "jump-overs", "box jumps over"]
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
            return ["pistol squats", "pistol squat", "single leg squat", "pistols", "alternating pistols", "alternating pistol squats"]
        case .handstandWalk:
            return ["handstand walk", "HS walk", "HSWALK"]
        case .ringDips:
            return ["ring dips", "gymnastic ring dips"]
        case .ropeClimb:
            return ["rope climb", "rope climbing", "climb rope"]
        case .plank:
            return ["plank", "front plank", "forearm plank", "plank on arms", "plank on forearms", "plank hold", "single leg plank", "one leg plank"]
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
            return ["devil press", "devil presses", "devils press", "dumbbell devil press", "DB devil press"]
        case .burpeeBoxJumps:
            return ["burpee box jumps", "burpee box jump", "BBJ", "burpee over box", "burpee box jump over"]
        case .burpeeOverBar:
            return ["burpee over bar", "burpees over bar", "burpee over the bar", "burpees over the bar", "BOTB", "burpee over barbell", "burpees over barbell", "bar facing burpee", "bar facing burpees", "BFB", "bar-facing burpees", "bar-facing burpee"]
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
            return ["lunges", "lunge", "walking lunges", "reverse lunges", "goblet lunges", "goblet reverse lunges", "barbell lunges", "barbell lunge", "dumbbell lunges", "DB lunges"]
        case .wallWalks:
            return ["wall walk", "wall walks", "WW"]
        case .vUps:
            return ["v-ups", "v ups", "v-up", "v up", "vups", "crossbody v-ups", "cross-body v-ups", "single leg v-ups", "alternating single leg v-ups"]
        case .chestToBarPullUps:
            return ["chest to bar pull-ups", "chest-to-bar pull-ups", "chest to bar pull ups", "chest to bar", "chest-to-bar", "C2B", "CTB"]
        case .ghdSitUps:
            return ["GHD sit-ups", "GHD sit ups", "GHD situps", "GHD sit-up", "GHD"]
        case .russianTwist:
            return ["russian twist", "russian twists"]
        case .lSit:
            return ["l-sit", "l sit", "l-sits", "l-sit hold", "lsit"]
        case .handstandShoulderTaps:
            return ["handstand shoulder taps", "shoulder taps", "wall facing shoulder taps"]
        case .gluteBridge:
            return ["glute bridge", "glute bridges", "one leg glute bridge", "single leg glute bridge", "hip thrust", "hip thrusts"]
        case .tricepsExtension:
            return ["triceps extension", "tricep extension", "triceps extensions", "triceps plate extension", "plate triceps extension", "skull crusher", "skull crushers"]
        case .plateRaise:
            return ["plate raise", "plate raises", "plate front raise", "front raise", "front raises"]
        case .landmineAntiRotation:
            return ["landmine anti-rotation", "landmine anti rotation", "landmine rotation", "landmine rotations", "landmine twist", "landmine twists"]
        case .boxStepUps:
            return ["box step-ups", "box step ups", "box step-up", "box step up", "step-ups", "step ups"]
        case .boxStepOvers:
            return ["box step over", "box step overs", "box step-over", "box step-overs", "step overs", "step-overs"]
        case .overheadCarry:
            return ["overhead carry", "overhead carries", "OH carry", "overhead walk"]
        case .bearHugCarry:
            return ["bear hug carry", "bear hug carries", "bear hug walk", "sandbag carry", "sandbag carries"]
        case .shoulderToOverhead:
            return ["shoulder to overhead", "shoulders to overhead", "shoulder-to-overhead", "S2O", "STOH", "STO"]
        case .catCow:
            return ["cat-cow", "cat cow", "cat camel", "cat-camel", "koci grzbiet"]
        case .birdDog:
            return ["bird dog", "bird-dog", "bird dogs", "quadruped arm leg raise"]
        case .deadBug:
            return ["dead bug", "deadbug", "dead bugs", "martwy robak"]
        case .childsPose:
            return ["child's pose", "childs pose", "child pose", "ukłon japoński"]
        case .pelvicTilt:
            return ["pelvic tilt", "pelvic tilts", "posterior pelvic tilt", "pelvic tilt knee to chest", "pelvic tilt with knee to chest", "podwinięcie miednicy"]
        case .hamstringStretch:
            return ["hamstring stretch", "hamstring stretches", "rozciąganie kulszowo-goleniowych"]
        case .gluteStretch:
            return ["glute stretch", "figure four stretch", "figure-four stretch", "figure-4 stretch", "figure 4 stretch", "figure 4 glute stretch", "figure four glute stretch", "piriformis stretch", "rozciąganie pośladka"]
        case .spinalTwist:
            return ["spinal twist", "spinal twists", "lying spinal twist", "supine twist", "trunk rotation", "trunk rotations", "torso rotation", "torso rotation stretch", "knee across body stretch", "knee over leg stretch", "knee crossover stretch", "supine knee crossover stretch", "skręty tułowia", "rotacja tułowia"]
        case .foamRolling:
            return ["foam rolling", "foam roll", "foam roller", "ball rolling", "lacrosse ball", "rolowanie"]
        case .proneArmRaises:
            return ["prone arm raises", "prone arm raise", "prone y raise", "prone y raises", "unoszenie ramion w leżeniu"]
        case .openBook:
            return ["open book", "open books", "open book stretch", "otwieranie książki"]
        case .threadTheNeedle:
            return ["thread the needle", "thread-the-needle", "nawlekanie igły"]
        case .thoracicExtension:
            return ["thoracic extension", "thoracic extensions", "foam roller extension", "thoracic extension on foam roller", "ekstensja piersiowa"]
        case .cobraStretch:
            return ["cobra stretch", "cobra", "prone press-up", "prone press-ups", "mckenzie press-up", "kobra"]
        case .wallSlides:
            return ["wall slides", "wall slide", "ślizgi po ścianie"]
        case .pigeonPose:
            return ["pigeon pose", "pigeon stretch", "gołąb"]
        case .couchStretch:
            return ["couch stretch", "hip flexor stretch", "lunge stretch", "rozciąganie zginaczy bioder"]
        case .ninetyNinety:
            return ["90/90", "90 90", "90/90 hip stretch", "90/90 hip switch", "90-90"]
        case .worldsGreatestStretch:
            return ["world's greatest stretch", "worlds greatest stretch", "WGS"]
        case .pvcPassThroughs:
            return ["pvc pass-throughs", "pvc pass throughs", "pass throughs", "pass-throughs", "pass through", "pass-through", "shoulder dislocates", "dislocates"]
        case .downwardDog:
            return ["downward dog", "downward facing dog", "downward-facing dog", "down dog", "pies z głową w dół"]
        case .unknown:
            return []
        }
    }

    public var category: MovementCategory {
        switch self {
        case .deadlift, .backSquat, .frontSquat, .benchPress, .floorPress, .shoulderPress, .overheadSquat,
             .romanianDeadlift, .bentOverRow, .gobletSquat, .bulgarianSplitSquat,
             .gluteBridge, .tricepsExtension, .plateRaise, .landmineAntiRotation:
            return .strength
        case .snatch, .cleanAndJerk, .powerClean, .powerSnatch, .hangPowerClean, .hangPowerSnatch,
             .hangClean, .pushPress, .pushJerk, .thrusters, .sumoDeadliftHighPull, .shoulderToOverhead:
            return .olympicLifting
        case .pullUps, .pushUps, .toesToBar, .sitUps, .handstandPushUps, .barMuscleUps, .ringMuscleUps,
             .pistolSquats, .handstandWalk, .ringDips, .ropeClimb, .plank, .chinUps, .skinTheCat,
             .kneesToElbows, .hollowHold,
             .wallWalks, .vUps, .chestToBarPullUps, .ghdSitUps, .russianTwist, .lSit, .handstandShoulderTaps:
            return .gymnastics
        case .running, .rowing, .cycling, .swimming, .assaultBike, .skiErg, .singleUnders:
            return .cardio
        case .burpees, .airSquat, .boxJumps, .doubleUnders, .wallBalls, .devilPress, .burpeeBoxJumps,
             .burpeeOverBar, .lunges, .mountainClimbers, .farmersCarry,
             .boxStepUps, .boxStepOvers, .overheadCarry, .bearHugCarry:
            return .mixed
        case .kettlebellSwing, .kettlebellClean, .kettlebellSnatch, .turkishGetUp:
            return .strength
        case .kettlebellPushPress:
            return .olympicLifting
        case .dumbbellSnatch, .dumbbellClean, .dumbbellCleanAndJerk:
            return .olympicLifting
        case .catCow, .birdDog, .deadBug, .childsPose, .pelvicTilt, .hamstringStretch,
             .gluteStretch, .spinalTwist, .foamRolling, .proneArmRaises,
             .openBook, .threadTheNeedle, .thoracicExtension, .cobraStretch, .wallSlides,
             .pigeonPose, .couchStretch, .ninetyNinety, .worldsGreatestStretch,
             .pvcPassThroughs, .downwardDog:
            return .mobility
        case .unknown:
            return .mixed
        }
    }

    /// Whether this exercise always involves load (kg).
    /// `true` means SetInputView should show a weight field even if the plan didn't specify one
    /// (e.g. Wall Balls always use a 6/9/14kg medicine ball).
    public var requiresWeight: Bool {
        switch self {
        case .wallBalls, .farmersCarry, .overheadCarry, .bearHugCarry:
            return true
        default:
            return category == .strength || category == .olympicLifting
        }
    }

    // MARK: - Catalog Matching

    /// Bumped whenever cases or aliases are extended. The one-time re-match job
    /// re-runs when its stored version is lower — same contract as the
    /// effort-points weights version: results frozen in the database are only
    /// recomputed through an explicit, versioned pass.
    public static let catalogVersion = 4

    /// Matches a raw OCR/AI exercise name against the catalog: exact match on
    /// `rawValue` and `aliases` (lowercased + trimmed), then distance-based
    /// suffix heuristics ("1,600-meter run" → `.running`). Returns `.unknown`
    /// when nothing matches — callers preserve the raw name so a later
    /// re-match can retry against an extended catalog.
    public static func matched(fromRawName name: String) -> ExerciseType {
        let normalized = name
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        for exerciseType in ExerciseType.allCases {
            if exerciseType.rawValue.lowercased() == normalized {
                return exerciseType
            }
            if exerciseType.aliases.contains(where: { $0.lowercased() == normalized }) {
                return exerciseType
            }
        }

        // Distance-based entries (e.g. "1,600-meter run", "5km row") — extract
        // the movement from the suffix.
        if normalized.hasSuffix("run") || normalized.contains("meter run") || normalized.contains("km run") || normalized.contains("mile run") {
            return .running
        }
        if normalized.hasSuffix("row") || normalized.contains("meter row") || normalized.contains("km row") {
            return .rowing
        }
        if normalized.hasSuffix("bike") || normalized.contains("meter bike") || normalized.contains("km bike") {
            return .cycling
        }

        return .unknown
    }
}
