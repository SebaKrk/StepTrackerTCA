////
////  ExerciseValidationTool.swift
////  MyFitnessJournal
////
////  Created by Sebastian Sciuba on 04/07/2025.
////
//
//import FoundationModels
//import SwiftUI
//
//@available(iOS 26, *)
//@Observable
//final class ExerciseValidationTool: Tool {
//    let name = "validateExercise"
//    let description = "Maps exercise names from OCR to correct ExerciseTypeAI enum values"
//    
//    @MainActor var validationHistory: [ValidationRecord] = []
//    
//    init() {}
//
//    @Generable
//    struct Arguments {
//        @Guide(description: "The exercise name from OCR text. Examples: 'DL', 'T2B', 'HSPU', 'sit up'")
//        let exerciseName: String
//    }
//    
//    @MainActor func recordValidation(exerciseName: String, result: ExerciseTypeAI) {
//        validationHistory.append(ValidationRecord(
//            input: exerciseName,
//            output: result
//        ))
//    }
//    
//    func call(arguments: Arguments) async throws -> ToolOutput {
//        let result = mapExercise(name: arguments.exerciseName)
//        await recordValidation(exerciseName: arguments.exerciseName, result: result)
//        
//        return ToolOutput(
//            "Exercise '\(arguments.exerciseName)' maps to: \(result.displayName)"
//        )
//    }
//    
//    private func mapExercise(name: String) -> ExerciseTypeAI {
//        let cleanName = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
//        
//        // Check all exercise types for exact matches
//        for exerciseType in ExerciseTypeAI.allCases {
//            // Check display name
//            if exerciseType.displayName.lowercased() == cleanName {
//                return exerciseType
//            }
//            
//            // Check aliases
//            for alias in exerciseType.aliases {
//                if alias.lowercased() == cleanName {
//                    return exerciseType
//                }
//            }
//        }
//        
//        // Simple partial matches for common cases
//        switch cleanName {
//        case let name where name.contains("dl") || name.contains("dead"):
//            return .deadlift
//        case let name where name.contains("t2b") || name.contains("toes"):
//            return .toesToBar
//        case let name where name.contains("hspu") || name.contains("handstand"):
//            return .handstandPushUps
//        case let name where name.contains("sit") && name.contains("up"):
//            return .sitUps
//        case let name where name.contains("push"):
//            return .pushUps
//        case let name where name.contains("pull"):
//            return .pullUps
//        case let name where name.contains("row"):
//            return .rowing
//        case let name where name.contains("squat"):
//            return .backSquat
//        default:
//            return .pushUps // Safe default
//        }
//    }
//}
//
//// MARK: - Supporting Types
//@available(iOS 26, *)
//struct ValidationRecord {
//    let input: String
//    let output: ExerciseTypeAI
//    let timestamp: Date = Date()
//}
