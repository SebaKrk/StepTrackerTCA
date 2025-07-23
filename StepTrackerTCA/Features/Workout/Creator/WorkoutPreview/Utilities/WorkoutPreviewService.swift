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
    
    //var workoutPlan: WorkoutPlan? = nil
    // workoutPlan = WorkoutPlan(.custom(createCrossfitWorkout()))
    //.workoutPreview(workoutPlan!, isPresented: $showPreview)
    
    // potrzebuje teraz moj --> TrainingSession
    // przemapowac na -->  CustomWorkout
    
    func mapTrainingSessionToCostumeWorkout(_ training: TrainingSession) -> CustomWorkout? {
        guard let warmUp = training.warmUp,
              let coolDown = training.coolDown else { return nil }

        let warmupStep = mapWarmUpSessionToWorkoutStep(warmUp)
        let cooldownStep = mapCoolDownSessionToWorkoutStep(coolDown)
        let blocks = mapWorkoutsToIntervalBlock(training.workouts)

        return CustomWorkout(
            activity: training.activity,
            location: training.location,
            displayName: training.title,
            warmup: warmupStep,
            blocks: blocks,
            cooldown: cooldownStep
        )
    }
    
    func mapWarmUpSessionToWorkoutStep(_ session: WarmUpSession) -> WorkoutStep {
        if session.goal == .timeLimit {
            WorkoutStep(
                goal: .time(Double(session.time ?? 0), .minutes),
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
                goal: .time(Double(session.time ?? 0), .minutes),
                alert: .heartRate(zone: 2)
            )
        } else {
            WorkoutStep(goal: .open,
                        alert: .heartRate(zone: 2)
            )
        }
    }
    
    func mapWorkoutsToIntervalBlock(_ workouts: [WorkoutSessionNew]) -> [IntervalBlock] {
        var steps: [IntervalStep] = []

        for (index, workout) in workouts.enumerated() {
            // Create .work step
            var workStep = IntervalStep(.work)
            workStep.purpose = .work
            workStep.step.displayName = workout.name
            if let timeCap = workout.timeCap {
                workStep.step.goal = .time(Double(timeCap), .minutes)
            } else {
                workStep.step.goal = .open
            }
            // TODO: czy dodac alerty ? odosnie strefy ?
            steps.append(workStep)

            if index < workouts.count - 1 {
                var recoveryStep = IntervalStep(.recovery)
                recoveryStep.purpose = .recovery
                recoveryStep.step.displayName = "Recovery"
                recoveryStep.step.goal = .time(5, .minutes)
                recoveryStep.step.alert = .heartRate(zone: 2)
                steps.append(recoveryStep)
            }
        }

        return [IntervalBlock(steps: steps, iterations: 1)]
    }

}

//let blocks: [IntervalBlock] = []
//
//
//var workout = IntervalStep(.work)
//workout.step.goal = .time(workouts.first?.timeCap, .minutes)
//workout.step.displayName = workouts.first?.name
//
//
//var recovery = IntervalStep(.recovery)
//recovery.purpose = .recovery
//recovery.step.displayName = "Recovery"
//recovery.step.goal = .time(5, .minutes)
//recovery.step.alert = .heartRate(zone: 2)
//
//
//IntervalBlock(steps: [workout], iterations: 1)


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
