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
    @State var seePreve: Bool = false
    @State var scheduledWorkouts: [ScheduledWorkoutPlan] = []
    
    // MARK: - View
    
    var body: some View {
        Group {
            VStack {
                if !scheduledWorkouts.isEmpty {
                    list
                } else {
                    Text("WorkoutPlanerFeature")
                }
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
                        seePreve = true
                    }
                    .workoutPreview(workoutPlan!, isPresented: $showPreview)
                }
                
                if workoutPlan != nil && seePreve == true {
                    Button {
                        guard let workout = workoutPlan else { return }
                        Task {
                            await schedule(workout: workout)
                        }
                    } label: {
                        Text("start in 5 min")
                    }
                }
                
            }
        }
        .task {
            scheduledWorkouts = await WorkoutScheduler.shared.scheduledWorkouts
        }
        
    }
    
    var list: some View {
        List {
            Section("Scheduled Workouts") {
                ForEach(scheduledWorkouts, id: \.self) { scheduledWorkout in
                    VStack(alignment: .leading) {
                        HStack {
                            Text(scheduledWorkout.plan.workout.activity.name)
                            
                            if scheduledWorkout.complete {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
            Section {
                Button {
                    Task {
                        await WorkoutScheduler.shared.removeAllWorkouts()
                        scheduledWorkouts = []
                    }
                } label: {
                    Text("Remove all scheduled workouts")
                }
            } header: {
                Text("remove all workouts")
            } footer: {
                Text("Usuwa z watcha")
            }
        }
        .frame(height: 200)
    }
    
    private func schedule(workout: WorkoutPlan) async {
        var components = DateComponents()
        components.minute = 5
        
        guard let targetDate = Calendar.current.date(byAdding: components, to: Date()) else {
            return
        }

        let targetComponents = Calendar.current.dateComponents(in: .current, from: targetDate)
        await WorkoutScheduler.shared.schedule(workout, at: targetComponents)
        
        scheduledWorkouts.append(ScheduledWorkoutPlan(workout, date: targetComponents))
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

// PacerWorkout
