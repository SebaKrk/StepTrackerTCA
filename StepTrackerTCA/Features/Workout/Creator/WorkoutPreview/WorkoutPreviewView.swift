//
//  WorkoutPreviewView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 17/07/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: WorkoutPreviewFeature.self)
struct WorkoutPreviewView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<WorkoutPreviewFeature>
    
    // MARK: - View
    
    var body: some View {
            Form {
                // MARK: - Basic Info Section
                Section("Informacje podstawowe") {
                    HStack {
                        Text("Data")
                        Spacer()
                        Text("\(store.trainingSession.date, style: .date)")
                            .foregroundColor(.secondary)
                    }
                }
                
                // MARK: - Warm Up Section
                if let warmUp = store.trainingSession.warmUp {
                    Section("Rozgrzewka") {
                        HStack {
                            Text("Cel")
                            Spacer()
                            Text(warmUp.goal == .open ? "Open" : "\(warmUp.time ?? 0) min")
                                .foregroundColor(.secondary)
                        }
                        
                        if let description = warmUp.description {
                            HStack {
                                Text("Opis")
                                Spacer()
                                Text(description)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                    }
                }
                
                // MARK: - Main Workout Section
                Section("Trening główny") {
                    ForEach(store.trainingSession.workouts) { workout in
                        VStack(alignment: .leading, spacing: 8) {
                            // Workout Header
                            HStack {
                                Text(workout.name)
                                    .font(.headline)
                                Spacer()
                            }
                            
                            // Workout Details
                            if let rounds = workout.rounds {
                                HStack {
                                    Text("Rundy")
                                    Spacer()
                                    Text("\(rounds)")
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            // Exercises
                            if !workout.exercises.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Ćwiczenia")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    ForEach(workout.exercises) { exercise in
                                        exerciseRow(exercise)
                                    }
                                }
                            }
                            
                            if let timeCap = workout.timeCap {
                                HStack {
                                    Spacer()
                                    Text("Limit czasu")
                                    Text("\(timeCap) min")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // MARK: - Cool Down Section
                if let coolDown = store.trainingSession.coolDown {
                    Section("Cool Down") {
                        HStack {
                            Text("Cel")
                            Spacer()
                            Text(coolDown.goal == .open ? "Open" : "\(coolDown.time ?? 0) min")
                                .foregroundColor(.secondary)
                        }
                        
                        if let description = coolDown.description {
                            HStack {
                                Text("Opis")
                                Spacer()
                                Text(description)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                    }
                }
                appleWatchButton
                iphoneButton
                saveButton
                if store.workoutPlan != nil {
                    previewApple
                }
                if store.seeWorkoutPlanPreview {
                    addToAppleWatch
                }
                
            }
            .navigationTitle("Podgląd treningu")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                send(.onAppear)
            }
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func exerciseRow(_ exercise: ExerciseSession) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("• \(exercise.type.rawValue.capitalized)")
                    .font(.body)
                
                if let target = exercise.target {
                    Spacer()
                    target.displayText
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let weight = exercise.weight {
                Text("Ciężary: M: \(weight.men ?? 0)kg / K: \(weight.women ?? 0)kg")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.leading, 8)
            }
            
            if let info = exercise.info {
                Text(info)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .italic()
                    .padding(.leading, 8)
            }
        }
    }
    
    private var appleWatchButton: some View {
        Button {
            
        } label: {
            Label("Start on Apple Watch", systemImage: "applewatch")
        }
    }
    
    private var iphoneButton: some View {
        Button {
            
        } label: {
            Label("Start on iPhone", systemImage: "iphone")
        }
    }
    
    private var saveButton: some View {
        Button {
        } label: {
            Label("Save for later", systemImage: "bookmark")
        }
    }
    
    private var previewApple: some View {
        Button {
            send(.showApplePreview)
        } label: {
            Label("show", systemImage: "applewatch")
        }
        .workoutPreview(store.workoutPlan!, isPresented: $store.showPreview)
    }
    
    private var addToAppleWatch: some View {
        Button {
            send(.addToAppleWatch)
        } label: {
            Label("ADD", systemImage: "applewatch")
        }
    }
    
    
}
