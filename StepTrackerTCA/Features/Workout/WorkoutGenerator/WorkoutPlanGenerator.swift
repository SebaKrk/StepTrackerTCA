//
//  WorkoutPlanGenerator.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 28/06/2025.
//

import FoundationModels

// Usage example
@available(iOS 26, *)
@MainActor
final class WorkoutPlanGenerator {
    //private(set) var parsedWorkout: String?
    private(set) var parsedWorkout: TrainingSessionAI.PartiallyGenerated?
    private var session: LanguageModelSession
    
    var error: Error?
    let ocrText: String  // Tekst przekazany w init
    
    init(ocrText: String) {
        self.ocrText = ocrText
        
        let tools: [any Tool] = [
            // Możesz dodać tools specyficzne dla tego tekstu
        ]
        
        self.session = LanguageModelSession(
            model: .default,
            tools: tools,
            instructions: {
                """
                You are a CrossFit workout text parser.
                
                Task: Analyze scanned CrossFit workout text and present it in clean, organized format.
                
                Rules:
                - Don't add your own comments or analysis
                - Don't translate abbreviations unless necessary
                - Keep original workout structure
                - Fix only obvious scanning errors (typos)
                - Format for better readability
                - For date: use format "Monday, January 15, 2025" or "2025-01-15"
                
                Format:
                1. 
                Type: [workout type] - Time: [duration]
                * [Exercise] - [details]
                * [Exercise] - [details]
                
                REST [time]
                
                2.
                Type: [workout type] - Time: [duration] 
                * [Exercise] - [details]
                * [Exercise] - [details]
                
                Just organize the text, don't add anything else.
                
                Here is the scanned text you need to parse:
                \(ocrText)
                """
            }
        )
    }
    
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
    
    func generateWorkoutPlan() async throws {
        let stream = session.streamResponse(
            generating: TrainingSessionAI.self,
            options: GenerationOptions(sampling: .greedy),
            includeSchemaInPrompt: true
        ) {
            "Parse the OCR text into a structured TrainingSessionAI object."
        }
        
        for try await partialResponse in stream {
            parsedWorkout = partialResponse
        }
    }
    
    func prewarm() {
        session.prewarm()
    }
}

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
