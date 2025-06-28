//
//  WorkoutPlanGenerator.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 28/06/2025.
//

import FoundationModels

// Usage example
@available(iOS 26, *)
class WorkoutPlanGenerator {
    private let session: LanguageModelSession
    
    init() {
        self.session = LanguageModelSession()
    }
    
    func generateWorkoutPlan(from ocrText: String) async throws {
        let prompt = """
        Analyze the following text recognized from an OCR training board and create a structured workout plan.
        
        TEXT TO ANALYZE: \(ocrText)
        
        TASKS:
        1. Extract only training elements (ignore names, results, word fragments)
        2. Automatically identify workout structure based on recognized elements
        3. Create a detailed workout plan
        
        NOTES:
        * Automatically recognize whether the workout has 1 or 2 main parts
        * Determine the type of each part based on content (STRENGTH/CONDITIONING/SKILL/ACCESSORY)
        * Focus only on readable training elements
        * Ignore word fragments, names, participant results
        * If something is unclear, provide the best interpretation
        * Add practical execution tips
        * Adapt warm-up and cool down to the type of workout performed
        
        WORKOUT SECTION TYPES:
        * STRENGTH: Sets/reps with 1RM percentages, heavy exercises
        * CONDITIONING: AMRAP, For Time, EMOM, Rounds, MetCon
        * SKILL/TECHNIQUE: Technique work, movement learning
        * ACCESSORY: Auxiliary exercises, isolated movements
        """
        
        let response = try await session.respond(
            to: prompt,
            generating: GeneratedWorkoutPlan.self
        )

        print(response.content)
        
    }
    
}
