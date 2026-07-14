//
//  ImageAnalysisView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 27/06/2025.
//

import ComposableArchitecture
import SwiftUI
import PhotosUI
import Vision

@ViewAction(for: ImageAnalysisFeature.self)
struct ImageAnalysisView: View {
    
    @Bindable var store: StoreOf<ImageAnalysisFeature>
    
    var body: some View {
        VStack(spacing: 20) {
            imageWithBoundingBoxes
            
            Button("Analyze Text") {
                send(.performOCR)
            }
            .disabled(store.isProcessingOCR)
            .buttonStyle(.borderedProminent)
            
            if store.isProcessingOCR {
                ProgressView("Processing...")
            }
            
            // Pokazuj listę rozpoznanego tekstu z numerami odpowiadającymi ramkom
            if !store.textObservations.isEmpty {
                recognizedTextList
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
        .navigationDestination(
            item: $store.scope(
                state: \.destination?.open,
                action: \.destination.open)) { store in
                    WorkoutGeneratorView(store: store)
                }
        .sheet(isPresented: $store.showImagePreview) {
            ImagePreviewSheet(
                image: store.selectedImage,
                observations: store.textObservations,
                onDismiss: { send(.hideImagePreview) }
            )
        }
    }
    
    // MARK: - Image with Bounding Boxes
    private var imageWithBoundingBoxes: some View {
        Button {
            send(.showImagePreview)
        } label: {
            Image(uiImage: store.selectedImage)
                .resizable()
                .scaledToFit()
                .overlay {
                    // 🔴 CZERWONE RAMKI WOKÓŁ ROZPOZNANEGO TEKSTU
                    ForEach(Array(store.textObservations.enumerated()), id: \.offset) { index, observation in
                        Box(observation: observation)
                            .stroke(.red, lineWidth: 2)
                            .overlay(
                                // Numerek w lewym górnym rogu ramki
                                Text("\(index + 1)")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                    .padding(2)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                    .offset(x: -8, y: -8),
                                alignment: .topLeading
                            )
                    }
                }
                .overlay(
                    // Ikona powiększenia w prawym górnym rogu
                    Image(systemName: "magnifyingglass")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                        .offset(x: -10, y: 10),
                    alignment: .topTrailing
                )
        }
        .buttonStyle(PlainButtonStyle())
        .padding()
    }
    
    // MARK: - Recognized Text List
    private var recognizedTextList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Rozpoznany tekst (\(store.textObservations.count) fragmentów):")
                    .font(.headline)
                    .padding(.bottom, 5)
                
                ForEach(Array(store.textObservations.enumerated()), id: \.offset) { index, observation in
                    editableTextRow(index: index, observation: observation)
                }
            }
            .padding(.horizontal)
        }
        .frame(maxHeight: 300)
    }
    
    // MARK: - Editable Text Row
    private func editableTextRow(index: Int, observation: RecognizedTextObservation) -> some View {
        HStack(alignment: .top, spacing: 10) {
            // Numerek odpowiadający ramce na obrazie
            Text("\(index + 1)")
                .font(.caption)
                .foregroundColor(.white)
                .padding(4)
                .background(Color.red)
                .clipShape(Circle())
                .frame(minWidth: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                // Edytowalny tekst lub TextField
                if store.editingIndex == index {
                    TextField("Edytuj tekst", text: .init(
                        get: { store.editableTexts.indices.contains(index) ? store.editableTexts[index] : "" },
                        set: { newValue in send(.updateText(index: index, newText: newValue)) }
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        send(.stopEditing)
                    }
                } else {
                    Text(store.editableTexts.indices.contains(index) ? store.editableTexts[index] : "")
                        .textSelection(.enabled)
                        .onTapGesture {
                            send(.startEditing(index: index))
                        }
                }
                
                HStack {
                    // Pokazuj confidence score
                    if let confidence = observation.topCandidates(1).first?.confidence {
                        Text("Pewność: \(Int(confidence * 100))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Kontrolki
                    HStack(spacing: 8) {
                        // Przycisk usuwania
                        Button {
                            send(.removeText(index: index))
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        // Przycisk edycji
                        if store.editingIndex == index {
                            Button("Gotowe") {
                                send(.stopEditing)
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        } else {
                            Button("Edytuj") {
                                send(.startEditing(index: index))
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)

        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - Action Button
    private var actionButton: some View {
        LabeledButton(title: "Convert to Workout", systemImage: "brain") {
            print("Send workout to Chat and convert to Workout")
            print("Recognized text: \(store.recognizedText)")
            send(.openWorkoutGenerator)
        }
        .disabled(store.recognizedText.isEmpty)
    }
}

