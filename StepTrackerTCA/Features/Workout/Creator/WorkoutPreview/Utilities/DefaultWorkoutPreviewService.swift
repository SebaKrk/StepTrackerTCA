//
//  DefaultWorkoutPreviewService.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 22/07/2025.
//

import Foundation
import WorkoutKit

protocol DefaultWorkoutPreviewService {
    func mapTrainingSessionToCustomWorkout(_ training: TrainingSession) -> CustomWorkout?
    
//    func scheduleWorkoutNow(workoutPlan: WorkoutPlan) async
    
    func addScheduleAndCheck(workoutPlan: WorkoutPlan) async -> Bool 
}
