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
    case squatClean
    case powerClean
    case powerSnatch

    case hangPowerClean
    case hangPowerSnatch
    case hangClean
    case pushPress
    case pushJerk
    case splitJerk
    case snatchBalance
    
    // CrossFit/Cardio (bodyweight + tempo)
    case pullUps
    case pushUps
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
    case kettlebellDeadlift
    case turkishGetUp

    // Medicine ball
    case ballSlam
    case medicineBallSquat
    case medicineBallBoxStepUps

    // Gymnastics
    case handstandPushUps
    case barMuscleUps
    case ringMuscleUps
    case pistolSquats
    case handstandWalk
    case ringDips
    case dips
    case ropeClimb
    case plank
    case chinUps
    case skinTheCat
    case kneesToElbows
    case hollowHold

    // Burpee family — one movement with a jumped-over object or an added skill.
    // The object is what you clear, not what you lift, so it stays part of the identity.
    case burpees
    case burpeeBoxJumps
    case burpeeBoxJumpOvers
    case burpeeOverBar
    case burpeeOverDumbbell
    case burpeePullUps
    case burpeeBroadJump
    case burpeeToTarget

    // CrossFit Classics
    case wallBalls
    case thrusters
    case devilPress
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

    // Strength accessories
    case gluteBridge
    case tricepsExtension
    case bicepCurl
    case goodMorning
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
        case .squatClean: return "Squat Clean"
        case .powerClean: return "Power Clean"
        case .powerSnatch: return "Power Snatch"
        case .hangPowerClean: return "Hang Power Clean"
        case .hangPowerSnatch: return "Hang Power Snatch"
        case .hangClean: return "Hang Clean"
        case .pushPress: return "Push Press"
        case .pushJerk: return "Push Jerk"
        case .splitJerk: return "Split Jerk"
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
        case .kettlebellDeadlift: return "Kettlebell Deadlift"
        case .turkishGetUp: return "Turkish Get-up"
        case .ballSlam: return "Ball Slam"
        case .medicineBallSquat: return "Medicine Ball Squat"
        case .medicineBallBoxStepUps: return "Medicine Ball Box Step-ups"
        case .handstandPushUps: return "Handstand Push-ups"
        case .barMuscleUps: return "Bar Muscle-ups"
        case .ringMuscleUps: return "Ring Muscle-ups"
        case .pistolSquats: return "Pistol Squats"
        case .handstandWalk: return "Handstand Walk"
        case .ringDips: return "Ring Dips"
        case .dips: return "Dips"
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
        case .burpeeBoxJumpOvers: return "Burpee Box Jump-Over"
        case .burpeeBroadJump: return "Burpee Broad Jump"
        case .burpeeToTarget: return "Burpee to Target"
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
        case .bicepCurl: return "Bicep Curl"
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
        case .snatchBalance: return "Snatch Balance"
        case .goodMorning: return "Good Morning"
        case .burpeePullUps: return "Burpee Pull-ups"
        case .burpeeOverDumbbell: return "Burpee Over Dumbbell"
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
        // Implement stays in these aliases: stripping it leaves "row", which the
        // distance heuristic reads as the rower.
        case .bentOverRow:
            return ["bent over row", "bent-over row", "barbell row", "pendlay row", "BOR", "BB row"]
        case .gobletSquat:
            return ["goblet squat", "goblet squats", "GS"]
        case .bulgarianSplitSquat:
            return ["bulgarian split squat", "bulgarian split squats", "BSS", "split squat", "rear foot elevated split squat", "RFESS"]
        case .benchPress:
            return ["bench press", "bench", "BP", "close-grip bench press", "close grip bench press", "close-grip bench", "close grip bench", "CGBP", "narrow grip bench press", "narrow-grip bench press", "wide grip bench press", "wide-grip bench press", "incline bench press", "decline bench press"]
        case .floorPress:
            return ["floor press", "floor bench press", "FP"]
        case .shoulderPress:
            return ["shoulder press", "strict press", "military press", "press", "seated overhead press", "seated shoulder press", "overhead press", "OHP"]
        case .overheadSquat:
            return ["overhead squat", "OHS"]
        case .snatch:
            return ["snatch", "snatches", "full snatch", "full snatches", "squat snatch", "squat snatches"]
        case .cleanAndJerk:
            return ["clean and jerk", "cleans and jerks", "clean & jerk", "cleans & jerks", "C&J", "C&Js", "CJ", "CJs", "hang clean and jerk", "hang cleans and jerks", "hang clean & jerk", "hang cleans & jerks", "hang clean jerk", "hang clean jerks", "hang C&J", "hang C&Js", "hang CJ", "hang CJs"]
        case .squatClean:
            return ["squat clean", "squat cleans", "clean", "cleans", "full clean", "full cleans"]
        case .powerClean:
            return ["power clean", "power cleans", "PC", "PCs"]
        case .powerSnatch:
            return ["power snatch", "power snatches", "PS", "PSs"]
        case .hangPowerClean:
            return ["HPC", "HPCs", "hang PC", "hang PCs", "hang power clean", "hang power cleans"]
        case .hangPowerSnatch:
            return ["HPS", "HPSs", "hang PS", "hang PSs", "hang power snatch", "hang power snatches"]
        case .hangClean:
            return ["hang clean", "hang cleans", "HC", "HCs", "hang squat clean", "hang squat cleans", "hang clean squat"]
        case .pushPress:
            return ["push press", "push presses", "push-press", "push-presses", "PP"]
        case .pushJerk:
            return ["push jerk", "push jerks", "push-jerk", "push-jerks", "PJ", "PJs"]
        case .splitJerk:
            return ["split jerk", "split jerks", "split-jerk", "split-jerks", "SJ"]
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
            return ["kettlebell swing", "KB swing", "american swing", "russian swing", "single arm swing", "single-arm swing", "single arm kettlebell swing", "single arm KB swing", "one arm swing", "one arm kettlebell swing"]
        case .kettlebellClean:
            return ["kettlebell clean", "KB clean"]
        case .kettlebellSnatch:
            return ["kettlebell snatch", "KB snatch"]
        case .kettlebellPushPress:
            return ["kettlebell push press", "KB push press", "KTB push press", "KB/DB push press", "DB push press", "dumbbell push press"]
        case .kettlebellDeadlift:
            return ["kettlebell deadlift", "kettlebell deadlifts", "KB deadlift", "KB deadlifts", "kettlebell dead lift", "KTB deadlift"]
        case .turkishGetUp:
            return ["turkish get-up", "turkish getup", "TGU"]
        case .ballSlam:
            return ["ball slam", "ball slams", "medicine ball slam", "medicine ball slams", "med ball slam", "med ball slams", "medball slam", "medball slams", "slam ball", "slam balls", "slamball"]
        case .medicineBallSquat:
            return ["medicine ball squat", "medicine ball squats", "med ball squat", "med ball squats", "medball squat", "medball squats"]
        case .medicineBallBoxStepUps:
            return ["medicine ball box step-ups", "medicine ball box step ups", "medicine ball box step-up", "medicine ball box step up", "medicine ball step-ups", "medicine ball step ups", "med ball box step-ups", "med ball box step ups", "med ball step-ups", "med ball step ups"]
        case .handstandPushUps:
            return ["handstand push-ups", "handstand pushups", "HSPU", "strict handstand push-ups", "strict HSPU"]
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
        case .dips:
            return ["dips", "dip", "box dips", "box dip", "bench dips", "bench dip", "bar dips", "bar dip", "parallel bar dips", "tricep dips", "triceps dips"]
        case .ropeClimb:
            return ["rope climb", "rope climbing", "climb rope"]
        case .plank:
            return ["plank", "front plank", "forearm plank", "plank on arms", "plank on forearms", "plank hold", "single leg plank", "one leg plank", "one arm plank", "single arm plank"]
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
            return ["thrusters", "thruster"]
        case .devilPress:
            return ["devil press", "devil presses", "devils press", "dumbbell devil press", "DB devil press"]
        case .burpeeBoxJumps:
            return ["burpee box jumps", "burpee box jump", "BBJ"]
        // Split from .burpeeBoxJumps: clearing the box is a different standard
        // from landing on it, and CrossFit scores them as separate movements.
        case .burpeeBoxJumpOvers:
            return ["burpee box jump over", "burpee box jump overs", "burpee box jump-over",
                    "burpee over box", "burpees over box", "BBJO", "lateral burpee over box"]
        case .burpeeBroadJump:
            return ["burpee broad jump", "burpee broad jumps", "broad jump burpee"]
        case .burpeeToTarget:
            return ["burpee to target", "burpees to target", "target burpee", "burpee to a target"]
        // Implement stays in these aliases: stripping it leaves "burpee over",
        // which matches nothing.
        case .burpeeOverBar:
            return ["burpee over bar", "burpees over bar", "burpee over the bar", "burpees over the bar", "BOTB", "burpee over barbell", "burpees over barbell", "bar facing burpee", "bar facing burpees", "BFB", "bar-facing burpees", "bar-facing burpee", "lateral burpee over bar", "lateral burpee over the bar", "lateral bar-facing burpee"]
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
        case .snatchBalance:
            return ["snatch balance", "snatch balances"]
        case .goodMorning:
            return ["good morning", "good mornings", "GM"]
        case .burpeePullUps:
            return ["burpee pull-ups", "burpee pull up"]
        // The implement stays in the name here: in "burpee over X" the object is
        // the thing jumped over, not the thing lifted, so stripping it leaves no movement.
        case .burpeeOverDumbbell:
            return ["burpee over dumbbell", "dumbbell facing burpee", "burpee over db", "burpees over db", "burpee over dumbbells", "lateral burpee over dumbbell", "db facing burpee", "db facing burpees"]
        case .lunges:
            return ["lunges", "lunge", "walking lunges", "reverse lunges", "goblet lunges", "goblet reverse lunges", "overhead reverse lunges", "overhead lunges"]
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
            return ["triceps extension", "tricep extension", "triceps extensions", "triceps plate extension", "plate triceps extension", "skull crusher", "skull crushers", "overhead triceps extension", "overhead tricep extension", "overhead extension"]
        case .bicepCurl:
            return ["bicep curl", "bicep curls", "biceps curl", "biceps curls", "hammer curl", "hammer curls", "EZ bar curl", "EZ bar curls", "curl", "curls"]
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
             .gluteBridge, .tricepsExtension, .plateRaise, .landmineAntiRotation, .bicepCurl,
             .goodMorning:
            return .strength
        case .snatch, .cleanAndJerk, .squatClean, .powerClean, .powerSnatch, .hangPowerClean, .hangPowerSnatch,
             .hangClean, .pushPress, .pushJerk, .splitJerk, .thrusters, .sumoDeadliftHighPull, .shoulderToOverhead,
             .snatchBalance:
            return .olympicLifting
        case .pullUps, .pushUps, .toesToBar, .sitUps, .handstandPushUps, .barMuscleUps, .ringMuscleUps,
             .pistolSquats, .handstandWalk, .ringDips, .dips, .ropeClimb, .plank, .chinUps, .skinTheCat,
             .kneesToElbows, .hollowHold,
             .wallWalks, .vUps, .chestToBarPullUps, .ghdSitUps, .russianTwist, .lSit, .handstandShoulderTaps:
            return .gymnastics
        case .running, .rowing, .cycling, .swimming, .assaultBike, .skiErg, .singleUnders:
            return .cardio
        case .burpees, .airSquat, .boxJumps, .doubleUnders, .wallBalls, .devilPress, .burpeeBoxJumps,
             .burpeeOverBar, .lunges, .mountainClimbers, .farmersCarry,
             .boxStepUps, .boxStepOvers, .overheadCarry, .bearHugCarry,
             .ballSlam, .medicineBallSquat, .medicineBallBoxStepUps,
             .burpeePullUps, .burpeeOverDumbbell, .burpeeBoxJumpOvers,
             .burpeeBroadJump, .burpeeToTarget:
            return .mixed
        case .kettlebellSwing, .kettlebellClean, .kettlebellSnatch, .turkishGetUp, .kettlebellDeadlift:
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
        case .farmersCarry, .overheadCarry, .bearHugCarry:
            return true
        default:
            return category == .strength || category == .olympicLifting
        }
    }

    /// Catalog name with the implement spelled out only when it is not the movement's
    /// usual one: "Snatch" stays plain, "DB Snatch" says what is unusual.
    ///
    /// Takes the DETECTED implement, not the effective one — comparing the effective
    /// implement against the default would never differ, so nothing would ever show.
    public func displayName(with equipment: Equipment?) -> String {
        guard let equipment, equipment != defaultEquipment else { return displayName }
        return "\(equipment.namePrefix) \(displayName)"
    }

    /// Implement the movement is normally performed with.
    ///
    /// Lets a name stay quiet about the obvious — a snatch is a barbell snatch — and
    /// speak up only when the implement is unusual ("DB Snatch"). `nil` means no
    /// implement is the obvious one, which is the correct answer for gymnastics,
    /// cardio, mobility, and for movements done equally often with and without load.
    public var defaultEquipment: Equipment? {
        switch self {
        case .snatch, .cleanAndJerk, .squatClean, .powerClean, .powerSnatch,
             .hangPowerClean, .hangPowerSnatch, .hangClean, .pushPress, .pushJerk,
             .splitJerk, .thrusters, .sumoDeadliftHighPull, .shoulderToOverhead,
             .deadlift, .backSquat, .frontSquat, .benchPress, .floorPress,
             .shoulderPress, .overheadSquat, .romanianDeadlift, .bentOverRow,
             .snatchBalance, .goodMorning:
            return .barbell

        case .kettlebellSwing, .kettlebellClean, .kettlebellSnatch, .kettlebellPushPress,
             .kettlebellDeadlift, .turkishGetUp, .gobletSquat:
            return .kettlebell

        case .dumbbellSnatch, .dumbbellClean, .dumbbellCleanAndJerk, .devilPress:
            return .dumbbell

        case .wallBalls, .ballSlam, .medicineBallSquat, .medicineBallBoxStepUps:
            return .medicineBall

        default:
            return nil
        }
    }

    // MARK: - Catalog Matching

    /// Bumped whenever cases or aliases are extended. The one-time re-match job
    /// re-runs when its stored version is lower — same contract as the
    /// effort-points weights version: results frozen in the database are only
    /// recomputed through an explicit, versioned pass.
    public static let catalogVersion = 7

    // MARK: Name normalisation

    /// Lowercases, folds separators to spaces and drops filler words, so that
    /// "Burpee Over The Bar" and "burpee-over-bar" reach the catalog identically.
    private static func normalized(_ raw: String) -> String {
        raw.lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .map(String.init)
            .filter { !$0.isEmpty && $0 != "the" }
            .joined(separator: " ")
    }

    /// Drops a single trailing plural "s", so "goblet squats" reaches "goblet squat".
    private static func singularized(_ name: String) -> String {
        name.hasSuffix("s") ? String(name.dropLast()) : name
    }

    /// Normalized names — and their singular forms — mapped to catalog entries.
    ///
    /// Built once. The previous linear scan walked every case and every alias on each
    /// scanned exercise and on each record the re-match job touches. First writer wins,
    /// which preserves the old "first matching case" semantics.
    private nonisolated static let aliasIndex: [String: ExerciseType] = {
        var index: [String: ExerciseType] = [:]
        for exerciseType in ExerciseType.allCases where exerciseType != .unknown {
            for candidate in [exerciseType.rawValue] + exerciseType.aliases {
                let key = normalized(candidate)
                guard !key.isEmpty else { continue }
                if index[key] == nil { index[key] = exerciseType }
                let singular = singularized(key)
                if index[singular] == nil { index[singular] = exerciseType }
            }
        }
        return index
    }()

    /// Looks a normalized name up, falling back to its singular form.
    private static func indexed(_ name: String) -> ExerciseType? {
        guard !name.isEmpty else { return nil }
        return aliasIndex[name] ?? aliasIndex[singularized(name)]
    }

    // MARK: Implement detection

    /// Implement tokens, longest first so "single dumbbell" wins over "dumbbell".
    private nonisolated static let equipmentTokens: [(token: String, equipment: Equipment)] = [
        ("single dumbbell", .dumbbell), ("double dumbbell", .dumbbell),
        ("single db", .dumbbell), ("double db", .dumbbell),
        ("single kettlebell", .kettlebell), ("double kettlebell", .kettlebell),
        ("medicine ball", .medicineBall), ("med ball", .medicineBall),
        ("dumbbells", .dumbbell), ("dumbbell", .dumbbell), ("db", .dumbbell),
        ("kettlebells", .kettlebell), ("kettlebell", .kettlebell), ("kb", .kettlebell),
        ("barbell", .barbell), ("bb", .barbell),
    ]

    /// Removes one implement token from an already normalized name.
    ///
    /// Returns `nil` when no token is present, when tokens of two different implements
    /// appear (too ambiguous to guess), or when nothing would be left of the name.
    private static func strippingEquipment(from name: String) -> (name: String, equipment: Equipment)? {
        let words = name.split(separator: " ").map(String.init)
        var distinct: Set<Equipment> = []
        var hit: (range: Range<Int>, equipment: Equipment)?

        for (token, equipment) in equipmentTokens {
            let tokenWords = token.split(separator: " ").map(String.init)
            guard let start = firstIndex(of: tokenWords, in: words) else { continue }
            distinct.insert(equipment)
            if hit == nil { hit = (start ..< (start + tokenWords.count), equipment) }
        }

        guard distinct.count == 1, let hit else { return nil }
        var remaining = words
        remaining.removeSubrange(hit.range)
        let stripped = remaining.joined(separator: " ")
        return stripped.isEmpty ? nil : (stripped, hit.equipment)
    }

    /// Index of the first whole-word occurrence of `needle` inside `haystack`.
    private static func firstIndex(of needle: [String], in haystack: [String]) -> Int? {
        guard !needle.isEmpty, haystack.count >= needle.count else { return nil }
        for start in 0 ... (haystack.count - needle.count)
        where Array(haystack[start ..< start + needle.count]) == needle {
            return start
        }
        return nil
    }

    /// Distance-based entries ("1,600-meter run", "5km row") — the movement is in the suffix.
    private static func distanceHeuristic(_ name: String) -> ExerciseType? {
        if name.hasSuffix("run") || name.contains("meter run") || name.contains("km run") || name.contains("mile run") {
            return .running
        }
        if name.hasSuffix("row") || name.contains("meter row") || name.contains("km row") {
            return .rowing
        }
        if name.hasSuffix("bike") || name.contains("meter bike") || name.contains("km bike") {
            return .cycling
        }
        return nil
    }

    // MARK: Resolution

    /// Resolves a raw OCR/AI name into a movement and, when the name says so, the
    /// implement it was performed with.
    ///
    /// Order is part of the contract. A whole-name match is tried first, so names that
    /// carry the implement in their identity ("kettlebell swing" → `.kettlebellSwing`)
    /// keep resolving exactly as before; only on a miss is an implement token stripped.
    /// Returns `.unknown` when nothing matches — callers preserve the raw name so a
    /// later re-match can retry against an extended catalog.
    public static func resolve(rawName: String) -> (type: ExerciseType, equipment: Equipment?) {
        let target = normalized(rawName)

        if let exerciseType = indexed(target) {
            return (exerciseType, nil)
        }

        if let stripped = strippingEquipment(from: target),
           let exerciseType = indexed(stripped.name) {
            return (exerciseType, stripped.equipment)
        }

        if let exerciseType = distanceHeuristic(target) {
            return (exerciseType, nil)
        }

        return (.unknown, nil)
    }

    /// Movement-only resolution, for callers that do not care about the implement.
    public static func matched(fromRawName name: String) -> ExerciseType {
        resolve(rawName: name).type
    }
}
