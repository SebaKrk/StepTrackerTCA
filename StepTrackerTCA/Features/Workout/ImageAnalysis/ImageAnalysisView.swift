//
//  ImageAnalysisView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 13/05/2025.
//


import ComposableArchitecture
import SwiftUI
import PhotosUI

//@ViewAction(for: ImageAnalysisFeature.self)
//struct ImageAnalysisView: View {
//    
//    // MARK: - Properties
//    
//    @Bindable var store: StoreOf<ImageAnalysisFeature>
//    
//    // MARK: - View
//    
//    var body: some View {
//        VStack {
//            image
//            Spacer()
//            actionButton
//        }
//    }
//    
//    // MARK: - SubView
//    
//    private var image: some View {
//        Image(uiImage: store.selectedImage )
//            .resizable()
//            .scaledToFit()
//            .padding()
//    }
//    
//    private var actionButton: some View {
//        LabeledButton(title: "Convert to Workout", systemImage: "brain") {
//            print("Send workout to Chat and convert to Workout")
//        }
//    }
//}

@ViewAction(for: ImageAnalysisFeature.self)
struct ImageAnalysisView: View {
    
    @Bindable var store: StoreOf<ImageAnalysisFeature>
    
    var body: some View {
        VStack(spacing: 20) {
            image
            
            // OCR Button
            Button("Analyze Text") {
                send(.performOCR)
            }
            .disabled(store.isProcessingOCR)
            .buttonStyle(.borderedProminent)
            
            // Loading indicator
            if store.isProcessingOCR {
                ProgressView("Processing...")
            }
            
            // Results
            if !store.recognizedText.isEmpty {
                ScrollView {
                    Text(store.recognizedText)
                        .textSelection(.enabled)
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .frame(maxHeight: 200)
            }
            
            // Error
            if let error = store.ocrError {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .padding()
            }
            
            Spacer()
            actionButton
        }
        .padding()
    }
    
    private var image: some View {
        Image(uiImage: store.selectedImage)
            .resizable()
            .scaledToFit()
            .padding()
    }
    
    private var actionButton: some View {
        LabeledButton(title: "Convert to Workout", systemImage: "brain") {
            print("Send workout to Chat and convert to Workout")
            print("Recognized text: \(store.recognizedText)")
        }
    }
}
