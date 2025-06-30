//
//  ImageAnalysisFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 27/06/2025.
//

import ComposableArchitecture
import Foundation
import Vision

@Reducer
struct ImageAnalysisFeature {
    
    // MARK: - Properties
    
    let services: ImageAnalysisService

    // MARK: - Lifecycle
    
    init(service: ImageAnalysisService = DefaultImageAnalysisService()) {
        self.services = service
    }
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        CombineReducers {
            BindingReducer()
            Reduce { state, action in
                switch action {
                    
                case .binding(_):
                    return .none
                    
                case .view(.viewDidAppear):
                    return .none
                    
                case .view(.performOCR):
                    state.isProcessingOCR = true
                    state.ocrError = nil
                    
                    return .run { [image = state.selectedImage] send in
                        do {
                            let observations = try await services.performOCR(on: image)
                            await send(.view(.ocrCompleted(observations)))
                        } catch {
                            await send(.view(.ocrFailed(error.localizedDescription)))
                        }
                    }
                    
                case let .view(.ocrCompleted(observations)):
                    state.isProcessingOCR = false
                    state.textObservations = observations
                    
                    // Inicjalizuj editable texts z OCR wyników
                    state.editableTexts = observations.compactMap { observation in
                        observation.topCandidates(1).first?.string ?? ""
                    }
                    
                    // Konwertuj na String dla WorkoutGenerator
                    state.recognizedText = state.editableTexts.joined(separator: "\n")
                    return .none
                    
                case let .view(.updateText(index, newText)):
                    // Aktualizuj tekst na konkretnym indeksie
                    if index < state.editableTexts.count {
                        state.editableTexts[index] = newText
                        
                        // Zaktualizuj recognizedText dla WorkoutGenerator
                        state.recognizedText = state.editableTexts.joined(separator: "\n")
                    }
                    return .none
                    
                case let .view(.startEditing(index)):
                    state.editingIndex = index
                    return .none
                    
                case .view(.stopEditing):
                    state.editingIndex = nil
                    return .none
                    
                case let .view(.removeText(index)):
                    // Usuń element z wszystkich tablic
                    if index < state.textObservations.count {
                        state.textObservations.remove(at: index)
                    }
                    if index < state.editableTexts.count {
                        state.editableTexts.remove(at: index)
                    }
                    
                    // Zaktualizuj recognizedText
                    state.recognizedText = state.editableTexts.joined(separator: "\n")
                    
                    // Reset editing index jeśli był ustawiony
                    if state.editingIndex == index {
                        state.editingIndex = nil
                    } else if let currentEditingIndex = state.editingIndex, currentEditingIndex > index {
                        // Dostosuj indeks edycji jeśli usuwamy element przed nim
                        state.editingIndex = currentEditingIndex - 1
                    }
                    return .none
                    
                case .view(.showImagePreview):
                    state.showImagePreview = true
                    return .none
                    
                case .view(.hideImagePreview):
                    state.showImagePreview = false
                    return .none
                    
                case let .view(.ocrFailed(error)):
                    state.isProcessingOCR = false
                    state.ocrError = error
                    return .none
                    
                case .view(.openWorkoutGenerator):
                    state.destination = .open(WorkoutGeneratorFeature.State(recognizedText: state.recognizedText))
                    return .none
                    
                case .destination:
                    return .none
                }
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}
