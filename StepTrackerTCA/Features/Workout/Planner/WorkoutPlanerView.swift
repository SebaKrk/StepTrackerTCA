//
//  WorkoutPlanerView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 09/05/2025.
//

import ComposableArchitecture
import SwiftUI

import HealthKit
import WorkoutKit

@ViewAction(for: WorkoutPlanerFeature.self)
struct WorkoutPlanerView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<WorkoutPlanerFeature>
    
    @State var workoutPlan: WorkoutPlan? = nil
    @State var showPreview: Bool = false
    
    // MARK: - View
    
    var body: some View {
        VStack {
            Text("WorkoutPlanerFeature")
            Button {
                workoutPlan = WorkoutPlan(.custom(createCrossfitWorkout()))
            } label: {
                Text("create workout")
            }
            HStack {
                Spacer()
                Text("or")
                Spacer()
            }
            Button {
                workoutPlan = WorkoutPlan(.goal(createSingleWorkout()))
            } label: {
                Text("create single workout")
            }
            
            if workoutPlan != nil {
                Button("Present Workout Preview") {
                    showPreview.toggle()
                }
                .workoutPreview(workoutPlan!, isPresented: $showPreview)
            }
        }
        
    }
    
    func createSingleWorkout() -> SingleGoalWorkout {
        SingleGoalWorkout(activity: .crossTraining, location: .indoor, goal: .energy(300, .kilocalories))
    }
    
    private func createCrossfitWorkout() -> CustomWorkout {
        
        let warmup = WorkoutStep(
            goal: .open, // .energy(75, .kilocalories)
            alert: .heartRate(zone: 2),
            displayName: "Rozgrzewka"
        )
        
        let block1 = createStrengthTrainingBlock()
        
        let transition = createTransitionBlock()
        
        let block2 = createFitnessTrainingBlock()
        
        let cooldownStep = WorkoutStep(goal: .time(5, .minutes))
        
        
        return CustomWorkout(
            activity: .crossTraining,
            location: .indoor,
            displayName: "Crossfit",
            warmup: warmup,
            blocks: [block1, transition, block2],
            cooldown: cooldownStep
        )
    }
    
    func createStrengthTrainingBlock() -> IntervalBlock {
        var workout = IntervalStep(.work)
        workout.step.goal = .open
        workout.step.displayName = "Block One"
        
        let workoutBlock = IntervalBlock(
            steps: [workout],
            iterations: 1
        )

        return workoutBlock
    }
    
    func createTransitionBlock() -> IntervalBlock {
        
        var transitionToZone1 = IntervalStep(.recovery)
        transitionToZone1.purpose = .recovery
        transitionToZone1.step.alert = .heartRate(zone: 1)
        transitionToZone1.step.goal = .open
        transitionToZone1.step.displayName = "Przejście do strefy 1"

        let transitionBlock = IntervalBlock(
            steps: [transitionToZone1],
            iterations: 1
        )

        return transitionBlock
    }
    
    func createFitnessTrainingBlock() -> IntervalBlock {
        var workout = IntervalStep(.work)
        workout.purpose = .work
        workout.step.alert = .heartRate(zone: 4)
        //workout.step.alert = .speed(10...15, unit: .milesPerHour, metric: .current)
        workout.step.goal = .open
        workout.step.displayName = "Block Two"
        
        let workoutBlock = IntervalBlock(
            steps: [workout],
            iterations: 1
        )

        return workoutBlock
    }
    
}

//workoutPreview
