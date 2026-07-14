//
//  SettingsView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 09/05/2025.
//

import SwiftUI
import WorkoutKit

struct SettingsView: View {
    
    @State var authorizationState: WorkoutScheduler.AuthorizationState = .notDetermined
    @State var scheduledWorkouts: [ScheduledWorkoutPlan] = []
    
    var body: some View {
        List {
            workoutSchedulerSection
        }
    }
    
    private var workoutSchedulerSection: some View {
        Section {
            Button("Request Authorization") {
                Task {
                    authorizationState = await WorkoutScheduler.shared.requestAuthorization()
                }
            }
            .disabled(authorizationState != .notDetermined)
        } header: {
            Text("Workout Scheduler")
        } footer: {
            Text("Current authorization state: \(String(describing: authorizationState))")
        }
    }
    
}
