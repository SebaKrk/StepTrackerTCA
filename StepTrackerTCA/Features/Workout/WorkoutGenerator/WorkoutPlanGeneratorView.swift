//
//  WorkoutPlanGeneratorView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 29/06/2025.
//

import SwiftUI
import FoundationModels

@available(iOS 26, *)
struct WorkoutPlanGeneratorView: View {
    
    @State private var workoutPlanGenerator: WorkoutPlanGenerator?
    @State private var isGenerating = false
    @State private var generatedWorkout: String?
    @State private var errorMessage: String?
    @State private var modelStatus: String = "Initializing..."
    
    let ocrText: String
    
    init(ocrText: String) {
        self.ocrText = ocrText
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Status header
                statusView
                
                // Main content
                mainContentView
            }
            .navigationTitle("AI Workout Parser")
            .navigationBarTitleDisplayMode(.inline)
            .padding()
        }
        .task {
            await initializeModel()
        }
    }
    
    private var statusView: some View {
        VStack(spacing: 8) {
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                
                Text(modelStatus)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if isGenerating {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var statusColor: Color {
        if isGenerating {
            return .orange
        } else if generatedWorkout != nil {
            return .green
        } else if errorMessage != nil {
            return .red
        } else if workoutPlanGenerator != nil {
            return .blue
        } else {
            return .gray
        }
    }
    
    @ViewBuilder
    private var mainContentView: some View {
        if isGenerating {
            loadingView
        } else if let workout = generatedWorkout {
            successView(workout: workout)
        } else if let error = errorMessage {
            errorView(error: error)
        } else {
            initialView
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "brain.head.profile")
                .font(.system(size: 48))
                .foregroundColor(.blue)
                .symbolEffect(.pulse)
            
            Text("🤖 AI is analyzing your workout...")
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text("Parsing exercises and organizing structure")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
    }
    
    private func successView(workout: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Generated Workout Plan", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundColor(.green)
                
                Spacer()
                
                Button("Regenerate") {
                    generateWorkout()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            ScrollView {
                Text(workout)
                    .textSelection(.enabled)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .frame(maxHeight: .infinity)
        }
    }
    
    private func errorView(error: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text("Generation Failed")
                .font(.headline)
                .foregroundColor(.red)
            
            Text(error)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Try Again") {
                generateWorkout()
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
    }
    
    private var initialView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                Text("🎯 AI Workout Generator")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Transform your scanned workout into organized format")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Preview of original text
            VStack(alignment: .leading, spacing: 8) {
                Text("Original Text:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(ocrText.prefix(100) + (ocrText.count > 100 ? "..." : ""))
                    .font(.caption)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal)
            
            Button {
                generateWorkout()
            } label: {
                Label("Generate Workout Plan", systemImage: "sparkles")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .disabled(workoutPlanGenerator == nil)
            .padding(.horizontal)
            
            Spacer()
        }
    }
    
    private func generateWorkout() {
        isGenerating = true
        errorMessage = nil
        generatedWorkout = nil
        modelStatus = "Generating workout plan..."
        
        Task {
            do {
                try await workoutPlanGenerator?.generateWorkoutPlan()
                
                await MainActor.run {
                    generatedWorkout = workoutPlanGenerator?.parsedWorkout
                    isGenerating = false
                    modelStatus = "Generation completed"
                }
                
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isGenerating = false
                    modelStatus = "Generation failed"
                }
            }
        }
    }
    
    private func initializeModel() async {
        let model = SystemLanguageModel(useCase: .general)
        
        await MainActor.run {
            modelStatus = "Checking model availability..."
        }
        
        print("SystemLanguageModel availability: \(model.availability)")
        print("SystemLanguageModel isAvailable: \(model.isAvailable)")
        
        await MainActor.run {
            if model.isAvailable {
                workoutPlanGenerator = WorkoutPlanGenerator(ocrText: ocrText)
                workoutPlanGenerator?.prewarm()
                modelStatus = "AI model ready"
            } else {
                modelStatus = "AI model unavailable: \(model.availability)"
                errorMessage = "Apple Intelligence is not available on this device"
            }
        }
    }
}
//struct WorkoutPlanGeneratorView: View {
//    
//    @State private var workoutPlanGenerator: WorkoutPlanGenerator?
//    @State private var modelStatus: String = "Checking..."
//    
//    let ocrText: String
//    
//    init(ocrText: String) {
//        self.ocrText = ocrText
//    }
//    
//    var body: some View {
//        VStack {
//            Text("Model Status: \(modelStatus)")
//                        .foregroundColor(.blue)
//                        .padding()
//                    
//            
//            if let parsedWorkout = workoutPlanGenerator?.parsedWorkout {
//                ScrollView {
//                    Text(parsedWorkout)
//                        .textSelection(.enabled)
//                        .padding()
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                        .background(Color(.systemGray6))
//                        .clipShape(RoundedRectangle(cornerRadius: 8))
//                }
//                .padding()
//            } else {
//                VStack {
//                    Text("🎯 AI Workout Generator Ready!")
//                        .font(.title2)
//                        .fontWeight(.semibold)
//                    
//                    Button {
//                        Task {
//                            do {
//                                try await workoutPlanGenerator?.generateWorkoutPlan()
//                            } catch {
//                                print("Error generating workout: \(error)")
//                                modelStatus = "Error: \(error.localizedDescription)"
//                            }
//                        }
//                    } label: {
//                        Label("Generate Workout Plan", systemImage: "sparkles")
//                            .fontWeight(.bold)
//                            .padding()
//                    }
//                    .buttonStyle(.bordered)
//                    .padding()
//                    .transition(.opacity)
//                }
//                .disabled(workoutPlanGenerator == nil)
//                .padding()
//            }
//        }
//        .task {
//            let model = SystemLanguageModel(useCase: .general)
//            modelStatus = "Availability: \(model.availability)"
//            print("SystemLanguageModel availability: \(model.availability)")
//            print("SystemLanguageModel isAvailable: \(model.isAvailable)")
//            
//            if model.isAvailable {
//                workoutPlanGenerator = WorkoutPlanGenerator(ocrText: ocrText)
//                workoutPlanGenerator?.prewarm()
//                modelStatus = "Ready"
//            } else {
//                modelStatus = "Model not available: \(model.availability)"
//            }
//        }
//    }
//}
