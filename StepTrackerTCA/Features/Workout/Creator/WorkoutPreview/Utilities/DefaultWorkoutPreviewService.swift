//
//  DefaultWorkoutPreviewService.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 22/07/2025.
//

import Foundation
import WorkoutKit

protocol DefaultWorkoutPreviewService {
    func mapTrainingSessionToCostumeWorkout(_ training: TrainingSession) -> CustomWorkout?
}
