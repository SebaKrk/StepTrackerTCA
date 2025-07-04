//
//  WorkoutPlanGenerator.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 28/06/2025.
//

import FoundationModels
import Foundation

@available(iOS 26, *)
@MainActor
final class WorkoutPlanGenerator {
    private(set) var parsedWorkout: TrainingSessionAI.PartiallyGenerated?
    private var session: LanguageModelSession
    private let exerciseValidationTool: ExerciseValidationTool
    
    var error: Error?
    let ocrText: String
    
    init(ocrText: String) {
        self.ocrText = ocrText
        
        self.exerciseValidationTool = ExerciseValidationTool()
        self.session = LanguageModelSession(
            model: .default,
            tools: [], // exerciseValidationTool// Dodaj narzędzia jeśli potrzebne
            instructions: Instructions {
                "You are a CrossFit workout parser that converts OCR text into structured TrainingSessionAI objects."
                
                "Your job is to:"
                "1. Parse the OCR text and extract ONLY the exercises that are clearly visible"
                "2. Create appropriate warm-up and cool-down based on the workout content"
                "3. Structure workouts properly with correct exercise types and targets"
                
                "CRITICAL RULES:"
                "- NEVER add exercises that are not in the OCR text"
                "- ALWAYS include warm-up and cool-down (suggest based on workout type)"
                "- Use current date: \(Date().ISO8601Format())"
                "- Match exercise types to the ExerciseTypeAI enum exactly"
                "- If exercise type is not in enum, use closest match and note in 'info' field"
                
                "EXERCISE TYPE MAPPING:"
                ExerciseTypeAI.allCases.map { exercise in
                    "- \(exercise.displayName): \(exercise.aliases.joined(separator: ", "))"
                }.joined(separator: "\n")
                
                "WORKOUT STRUCTURE RECOGNITION:"
                "- Sets/reps with percentages = Strength work"
                "- AMRAP/For Time/EMOM = Conditioning"
                "- Time caps indicate conditioning workouts"
                "- Multiple exercises in sequence = single workout"
                
                "WARM-UP SUGGESTIONS based on workout type:"
                "- Strength: 'Dynamic warm-up, joint mobility, and light movement preparation'"
                "- Weightlifting: 'Progressive warm-up with empty barbell, mobility, and activation'"
                "- CrossFit/Conditioning: 'General warm-up, movement prep, and heart rate elevation'"
                "- Cardio: 'Light cardio warm-up and dynamic stretching'"
                
                "COOL-DOWN SUGGESTIONS based on workout type:"
                "- Strength: 'Light stretching and mobility work'"
                "- Weightlifting: 'Cool-down stretching and joint decompression'"
                "- CrossFit/Conditioning: 'Cool-down walk, stretching, and breathing exercises'"
                "- Cardio: 'Gradual cool-down and static stretching'"
                
                "WEIGHT AND ROUNDS PARSING:"
                "- When you see percentages (e.g., 50-60% 1RM), put weight as nil and include percentage info in 'info' field"
                "- Count total rounds: 4x5 + 3x4 = 7 rounds total"
                "- Create separate exercises for different rep/percentage schemes"
                "- For kettlebell swings: Men 24-32kg, Women 16-24kg (use actual weights)"
                "- Only use weight field when specific kg amounts are clear, not percentages"
                
                "EXAMPLE PARSING:"
                """
                OCR Text: "SNATCH 4x5 @ 50-60% 3x4 @ 60-70% AMRAP 10' 10 American Swings 8 HSPU"
                
                Should create:
                - Workout 1: Snatch technique with 7 total rounds (4+3), two exercises with different rep schemes
                - Workout 2: AMRAP 10' with swings and HSPU (conditioning)
                - Use weight: nil for percentage-based exercises, actual kg for fixed weights
                - Put percentage info in 'info' field: "1-4 rounds at 50-60% 1RM"
                """
            }
        )
    }

    func generateWorkoutPlan() async throws {
        let stream = session.streamResponse(
            generating: TrainingSessionAI.self,
            options: GenerationOptions(sampling: .greedy),
            includeSchemaInPrompt: true
        ) {
            "Parse this OCR text into a structured TrainingSessionAI object:"
            
            "OCR TEXT TO PARSE:"
            ocrText
            
            "Remember:"
            "- Extract ONLY exercises that are clearly visible in the text"
            "- Create logical workout groupings"
            "- Always suggest appropriate warm-up and cool-down"
            "- Use exact exercise types from the enum"
            "- Include weight recommendations when percentages are given"
            
            "Here's an example of good structure, but don't copy it:"
            TrainingSessionAI.exampleCrossFitSession
        }
        
        for try await partialResponse in stream {
            parsedWorkout = partialResponse
        }
    }
    
    func prewarm() {
        session.prewarm()
    }
}

// MARK: - Example Training Session
@available(iOS 26, *)
extension TrainingSessionAI {
    static let exampleCrossFitSession = TrainingSessionAI(
        date: "2025-01-15T10:00:00Z",
        warmUp: WarmUpAI(
            description: "Progressive warm-up with empty barbell, mobility, and activation"
        ),
        workouts: [
            WorkoutAI(
                name: "Snatch Technique Work",
                timeCap: nil,
                rounds: 7,
                exercises: [
                    ExerciseAI(
                        type: .snatch,
                        target: .reps(5),
                        weight: nil,
                        info: "1-4 rounds at 50-60% 1RM"
                    ),
                    ExerciseAI(
                        type: .snatch,
                        target: .reps(4),
                        weight: nil,
                        info: "5-7 rounds at 60-70% 1RM"
                    )
                ]
            ),
            WorkoutAI(
                name: "AMRAP 10'",
                timeCap: 10,
                rounds: nil,
                exercises: [
                    ExerciseAI(
                        type: .kettlebellSwing,
                        target: .reps(16),
                        weight: WeightAI(men: 24, women: 16),
                        info: nil
                    ),
                    ExerciseAI(
                        type: .handstandPushUps,
                        target: .reps(8),
                        weight: nil,
                        info: nil
                    )
                ]
            )
        ],
        coolDown: CoolDownAI(
            description: "Cool-down stretching and joint decompression"
        )
    )
}

//// Usage example
//@available(iOS 26, *)
//@MainActor
//final class WorkoutPlanGenerator {
//    //private(set) var parsedWorkout: String?
//    private(set) var parsedWorkout: TrainingSessionAI.PartiallyGenerated?
//    private var session: LanguageModelSession
//    
//    var error: Error?
//    let ocrText: String  // Tekst przekazany w init
//    
//    init(ocrText: String) {
//        self.ocrText = ocrText
//        
//        let tools: [any Tool] = [
//            // Możesz dodać tools specyficzne dla tego tekstu
//        ]
//        
//        self.session = LanguageModelSession(
//            model: .default,
//            tools: tools,
//            instructions: {
//                """
//                You are a CrossFit workout text parser.
//                
//                Task: Analyze scanned CrossFit workout text and present it in clean, organized format.
//                
//                Rules:
//                - Don't add your own comments or analysis
//                - Don't translate abbreviations unless necessary
//                - Keep original workout structure
//                - Fix only obvious scanning errors (typos)
//                - Format for better readability
//                - For date: use format "Monday, January 15, 2025" or "2025-01-15"
//                
//                Format:
//                1. 
//                Type: [workout type] - Time: [duration]
//                * [Exercise] - [details]
//                * [Exercise] - [details]
//                
//                REST [time]
//                
//                2.
//                Type: [workout type] - Time: [duration] 
//                * [Exercise] - [details]
//                * [Exercise] - [details]
//                
//                Just organize the text, don't add anything else.
//                
//                Here is the scanned text you need to parse:
//                \(ocrText)
//                """
//            }
//        )
//    }
//
//    func generateWorkoutPlan() async throws {
//        let stream = session.streamResponse(
//            generating: TrainingSessionAI.self,
//            options: GenerationOptions(sampling: .greedy),
//            includeSchemaInPrompt: true
//        ) {
//            "Parse the OCR text into a structured TrainingSessionAI object."
//        }
//        
//        for try await partialResponse in stream {
//            parsedWorkout = partialResponse
//        }
//    }
//    
//    func prewarm() {
//        session.prewarm()
//    }
//}


//    func generateWorkoutPlan() async throws {
//        let stream = session.streamResponse(
//            generating: TrainingSessionAI.self,
//            includeSchemaInPrompt: false
//        ) {
//            "Parse and organize this CrossFit workout text into the specified format."
//        }
//
//        for try await partialResponse in stream {
//            parsedWorkout = partialResponse
//        }
//    }

//self.session = LanguageModelSession(model: .default,
//                                    //guardrails: <#T##LanguageModelSession.Guardrails#>, zdefinuj ograniczenia wiekowe prawne tokeny
//                                    tools: tools, // ExerciseDatabaseTool , moge mu dostarczyc baze danych z cwiczeniami
//                                    instructions: {


//    func generateWorkoutPlanTest(from ocrText: String) async throws {
//        let stream = session.streamResponse(
//            generating: Itinerary.self,
//            options: GenerationOptions(sampling: .greedy),
//            includeSchemaInPrompt: false
//        ) {
//            "Generate a \(dayCount)-day itinerary to \(landmark.name)."
//
//            "Give it a fun title and description."
//
//            "Here is an example, but don't copy it:"
//
//        }
//    }

//func generateWorkoutPlanTest(from ocrText: String) async throws {
//    let prompt = """
//    Analyze the following text recognized from an OCR training board and create a structured workout plan.
//    
//    TEXT TO ANALYZE: \(ocrText)
//    
//    TASKS:
//    1. Extract only training elements (ignore names, results, word fragments)
//    2. Automatically identify workout structure based on recognized elements
//    3. Create a detailed workout plan
//    
//    NOTES:
//    * Automatically recognize whether the workout has 1 or 2 main parts
//    * Determine the type of each part based on content (STRENGTH/CONDITIONING/SKILL/ACCESSORY)
//    * Focus only on readable training elements
//    * Ignore word fragments, names, participant results
//    * If something is unclear, provide the best interpretation
//    * Add practical execution tips
//    * Adapt warm-up and cool down to the type of workout performed
//    
//    WORKOUT SECTION TYPES:
//    * STRENGTH: Sets/reps with 1RM percentages, heavy exercises
//    * CONDITIONING: AMRAP, For Time, EMOM, Rounds, MetCon
//    * SKILL/TECHNIQUE: Technique work, movement learning
//    * ACCESSORY: Auxiliary exercises, isolated movements
//    """
//    
//    let response = try await session.respond(
//        to: prompt,
//        generating: GeneratedWorkoutPlan.self
//    )
//
//    print(response.content)
//    
//}
