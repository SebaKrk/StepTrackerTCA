//
//  WorkoutSectionType.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 28/06/2025.
//

import FoundationModels
 
// Enum for workout section types
@Generable
@available(iOS 26, *)
enum WorkoutSectionType: String, CaseIterable, Codable {
    case strength = "STRENGTH"
    case conditioning = "CONDITIONING"
    case skill = "SKILL/TECHNIQUE"
    case accessory = "ACCESSORY"
    case warmup = "WARM-UP"
    case cooldown = "COOL DOWN"
    case mobility = "MOBILITY"
    case additional = "ADDITIONAL"
}

// Structure for individual workout section
@Generable
@available(iOS 26, *)
struct GeneratedWorkoutSection {
    @Guide(description: "Type of workout section (STRENGTH, CONDITIONING, SKILL/TECHNIQUE, ACCESSORY)")
    var type: WorkoutSectionType
    
    @Guide(description: "Name/title of the workout section")
    var title: String
    
    @Guide(description: "List of detailed exercises or instructions for this section", .count(1...10))
    var exercises: [String]
    
    @Guide(description: "Additional notes or tips for this section")
    var notes: String?
}

// Main workout plan structure
@Generable
@available(iOS 26, *)
struct GeneratedWorkoutPlan {
    @Guide(description: "List of recognized workout elements from OCR text", .count(1...20))
    var recognizedElements: [String]
    
    @Guide(description: "Warm-up adapted to the main exercises")
    var warmUp: GeneratedWorkoutSection
    
    @Guide(description: "First main workout section")
    var mainSection1: GeneratedWorkoutSection
    
    @Guide(description: "Second main workout section (optional)")
    var mainSection2: GeneratedWorkoutSection?
    
    @Guide(description: "Accessory or additional exercises (optional)")
    var accessorySection: GeneratedWorkoutSection?
    
    @Guide(description: "Cool down/stretching adapted to the performed workout")
    var coolDown: GeneratedWorkoutSection
    
    @Guide(description: "Scaling options for different skill levels", .count(2...5))
    var scalingOptions: [String]
    
    @Guide(description: "General notes about the entire workout")
    var generalNotes: String?
}
