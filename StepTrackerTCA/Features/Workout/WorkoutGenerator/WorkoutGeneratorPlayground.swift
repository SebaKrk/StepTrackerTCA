//
//  WorkoutGeneratorPlayground.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 28/06/2025.
//

import FoundationModels
import Playgrounds

@available(iOS 26, *)
#Playground {
    let recognizedText = """
        AMlRAP1
        RKo 32/24 KG
        19x FRONT SQUATS @40/30
        Rxt: 28/20 kc
        18 x BOB
        18 x T2B
        19x BURPEES
        11/11x KB/DB PuSH PRESs 24/16
        REST 4'
        1 AMRAP 11:
    """
    
    let prompt = """
    Analyze the following text recognized from an OCR training board and create a structured workout plan.
    
    TEXT TO ANALYZE: \(recognizedText)

    TASKS:
    1. Extract only relevant training elements — ignore athlete names, scores, timecaps, unrelated notes or partial words.
    2. Classify each element into one of the training categories.
    3. Recognize and extract all LOAD information.
    4. Detect if the workout specifies RX / SCALED variants.
    5. Return a clean, structured training plan using Markdown formatting.
    6. Preserve logical workout order: STRENGTH → CONDITIONING → ACCESSORY → MOBILITY.
    """
 
    
    let session = LanguageModelSession()
    
    let response = try await session.respond(to: prompt)
//    let response = try await session.respond(to: prompt,
//                                             generating: GeneratedWorkoutPlan.self)
    
    dump(response)
}



let prompt1 = """
Analyze the following text recognized from an OCR training board and create a structured workout plan.

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

let prompt2 = """
Analyze ONLY the following OCR text from a training board. Do NOT add any exercises or elements that are not explicitly mentioned in the text.

TASK: Identify the basic workout structure

REQUIREMENTS:
1. What type of workout is this? (/CONDITIONING/SKILL/ACCESSORY/MOBILITY/ADDITIONAL)
2. How many workout sections are there?
3. What is the workout duration (if specified)?
4. List ONLY the exercises that are clearly readable in the OCR text

STRICT RULES:
- Use ONLY exercises mentioned in the original text
- Do NOT invent or add exercises like "TRX" or others not in the text
- If text is unclear, mark it as "unclear" rather than guessing
- Focus on factual analysis, not detailed workout plans

Example response format:
- Workout Type: [TYPE]
- Number of sections: [NUMBER]
- Duration: [TIME if specified]
- Exercises found: [LIST ONLY WHAT'S IN TEXT]
"""

let prompt3 = """
Analyze the following text recognized from an OCR training board and create a structured workout plan.
From the OCR-recognized training board text, extract and classify each workout element into categories such as STRENGTH, CONDITIONING, SKILL, ACCESSORY, MOBILITY, and ADDITIONAL.
Each training session consists of one or more of the above categories. If any category is not explicitly labeled, infer it based on the type of exercises, repetition schemes, and workout structure.


TASKS:
1. Extract only relevant training elements — ignore athlete names, scores, timecaps, unrelated notes or partial words.
2. Classify each element into one of the training categories.
3. Recognize and extract all LOAD information.
4. Detect if the workout specifies RX / SCALED variants.
5. Return a clean, structured training plan using Markdown formatting.
6. Preserve logical workout order: STRENGTH → CONDITIONING → ACCESSORY → MOBILITY.

WORKOUT SECTION TYPES:
• STRENGTH → Heavy lifting, %1RM, tempo, e.g. 5x5 Back Squat @ 80%
• CONDITIONING → Time-based or rep-based WODs, AMRAPs, EMOMs, etc.
• SKILL → Movement development, gymnastics, technique drills
• ACCESSORY → Isolation work, core, unilateral, bodybuilding-style
• MOBILITY → Prehab, cooldown, stretching, flow work
• ADDITIONAL → Extra notes, mindset, coach tips, lifestyle advice

LOAD RULES:
• X/Y Format (e.g. 24/16):
  - X → prescribed weight for men
  - Y → prescribed weight for women
  - Default unit: kg
• Percentage Format (e.g. 80%):
  - Indicates % of 1 Rep Max (1RM) for the exercise
  - Example: Clean @ 85% = 85% of 1RM Clean
• If both sets/reps and % appear → classify as STRENGTH
• Include weights next to movements if provided

RX / SCALED RULES:
• If the text contains "RX", interpret it as prescribed standard.
• If the text includes "Scaled", interpret it as a modified or reduced version.
• When both are listed, show both workout versions under respective labels:

  ### RX
  - 21-15-9 Thrusters (42.5/30kg) + Pull-ups

  ### SCALED
  - 21-15-9 Thrusters (30/20kg) + Ring Rows

CROSSFIT STRUCTURE TERMS GLOSSARY:
• AMRAP → As Many Rounds (or Reps) As Possible within a time limit
• EMOM → Every Minute On the Minute – perform specified reps every minute
• RFT → Rounds For Time – complete a set number of rounds as fast as possible
• FOR TIME → Complete all listed reps as fast as possible
• TABATA → 20 seconds on, 10 seconds off for 8 rounds (4 minutes total)
• CHIPPER → Complete a list of movements in order, one time through
• 1RM / 3RM / 5RM → 1/3/5 Rep Max – maximum weight for the given number of reps
• METCON → Metabolic Conditioning – usually a high-intensity conditioning block
• TEMPO → Controlled time for each movement phase (e.g. 32X1 = 3s down, 2s pause, explode, 1s up)


OUTPUT FORMAT (Markdown Example):

## STRENGTH
- Deadlift: 5x5 @ 80% 1RM
- Push Press: 5x3 @ 75%

## CONDITIONING – AMRAP 12'
- 10 KB swings (24/16 kg)
- 12 Wall balls
- 200m Run

### RX
- Thrusters: 42.5/30kg
- Pull-ups

### SCALED
- Thrusters: 30/20kg
- Jumping Pull-ups

## ACCESSORY
- Banded Face Pulls: 3x20
- GHD Sit-ups: 3x15

## MOBILITY
- Foam Roll Quads – 2 min each
- Pigeon Pose – 1 min/side
"""
