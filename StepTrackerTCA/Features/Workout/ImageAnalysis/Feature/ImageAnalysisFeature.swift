//
//  ImageAnalysisFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 13/05/2025.
//

import ComposableArchitecture
import Foundation
//@preconcurrency import Vision

@Reducer
struct ImageAnalysisFeature {
    
    // MARK: - Properties
    
    let services: ImageAnalysisService

    // MARK: - Livecycle
    
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
                            let text = try await services.performOCR(on: image)
                            await send(.view(.ocrCompleted(text)))
                        } catch {
                            await send(.view(.ocrFailed(error.localizedDescription)))
                        }
                    }
                    
                case let .view(.ocrCompleted(text)):
                    state.isProcessingOCR = false
                    state.recognizedText = text
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
