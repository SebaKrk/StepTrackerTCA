//
//  WorkoutGeneratorView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 27/06/2025.
//

import ComposableArchitecture
import SwiftUI
import PhotosUI
import FoundationModels

@ViewAction(for: WorkoutGeneratorFeature.self)
struct WorkoutGeneratorView: View {
    
    @Bindable var store: StoreOf<WorkoutGeneratorFeature>
    
    @available(iOS 26.0, *)
    private var model: SystemLanguageModel {
        SystemLanguageModel.default
    }
    
    var body: some View {
        rootView
    }
    
    @ViewBuilder
    private var rootView: some View {
        if #available(iOS 26, *) {
            generatorWorkoutView
        } else {
            rawText
        }
    }
    
    private var rawText: some View {
        ScrollView {
            Text(store.recognizedText)
                .textSelection(.enabled)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding()
    }
    
    @available(iOS 26.0, *)
    @ViewBuilder
    private var generatorWorkoutView: some View {
        switch model.availability {
        case .available:
            WorkoutPlanGeneratorView(ocrText: store.recognizedText)
            
        case .unavailable(.appleIntelligenceNotEnabled):
            Text("⚠️ Apple Intelligence not enabled")
                .foregroundColor(.orange)
            
        case .unavailable(.modelNotReady):
            Text("⏳ AI model loading...")
                .foregroundColor(.blue)
            
        case .unavailable(.deviceNotEligible):
            Text("❌ Device not compatible")
                .foregroundColor(.red)
            
        case .unavailable(_):
            Text("🚫 AI features unavailable")
                .foregroundColor(.gray)
        }
    }
    
}
