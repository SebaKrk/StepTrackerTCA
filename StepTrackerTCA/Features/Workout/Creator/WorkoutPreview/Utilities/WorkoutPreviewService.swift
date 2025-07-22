//
//  WorkoutPreviewService.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 22/07/2025.
//

import ComposableArchitecture
import Foundation
import WorkoutKit

final class WorkoutPreviewService: DefaultWorkoutPreviewService {
    
    
    // potrzebuje teraz moj --> TrainingSession
    // przemapowac na -->  CustomWorkout
    
    func mapTrainingSessionToCostumeWorkout(_ training: TrainingSession) -> CustomWorkout {
        let warmUp = mapWarmUpSessionToWorkoutStep(training)
        let coolDown = mapCoolDownSessionToWorkoutStep(training)
        return CustomWorkout(
            activity: .crossTraining,
            location: .indoor,
            displayName: "displayName",
            warmup: warmUp,
            blocks: <#T##[IntervalBlock]#>,
            cooldown: coolDown
        )
    }
    
    func mapWarmUpSessionToWorkoutStep(_ session: WarmUpSession) -> WorkoutStep {
        if session.goal == .timeLimit {
            WorkoutStep(
                goal: .time(session.time, .minutes),
                alert: .heartRate(zone: 2)
            )
        } else {
            WorkoutStep(goal: .open,
                        alert: .heartRate(zone: 2)
            )
        }
    }
    
    func mapCoolDownSessionToWorkoutStep(_ session: CoolDownSession) -> WorkoutStep {
        if session.goal == .timeLimit {
            WorkoutStep(
                goal: .time(session.time, .minutes),
                alert: .heartRate(zone: 2)
            )
        } else {
            WorkoutStep(goal: .open,
                        alert: .heartRate(zone: 2)
            )
        }
    }

}


// example 1
//struct TrainingSession {
//    let date: Date
//    let warmUp: WarmUpSession?
//    let workouts: [WorkoutSessionNew]
//    let coolDown: CoolDownSession?
//}

// example 2
//CustomWorkout(
//    activity: .crossTraining,
//    location: .indoor,
//    displayName: "Crossfit",
//    warmup: warmup,
//    blocks: [block1, transition, block2],
//    cooldown: cooldownStep
//)
