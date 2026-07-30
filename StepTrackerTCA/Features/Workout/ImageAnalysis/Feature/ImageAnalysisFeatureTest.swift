////
////  ImageAnalysisFeature.swift
////  StepTrackerTCA
////
////  Created by Sebastian Sciuba on 13/05/2025.
////
//
//import ComposableArchitecture
//import Foundation
//@preconcurrency import Vision
//
//@Reducer
//struct ImageAnalysisFeature {
//    
//    var body: some Reducer<State, Action> {
//        CombineReducers {
//            BindingReducer()
//            Reduce { state, action in
//                switch action {
//                    
//                case .binding(_):
//                    return .none
//                    
//                case .view(.viewDidAppear):
//                    return .none
//                    
//                case .view(.performOCR):
//                    state.isProcessingOCR = true
//                    state.ocrError = nil
//                    
//                    return .run { [image = state.selectedImage] send in
//                        do {
//                            let text = try await performOCR(on: image)
//                            await send(.view(.ocrCompleted(text)))
//                        } catch {
//                            await send(.view(.ocrFailed(error.localizedDescription)))
//                        }
//                    }
//                    
//                case let .view(.ocrCompleted(text)):
//                    state.isProcessingOCR = false
//                    state.recognizedText = text
//                    return .none
//                    
//                case let .view(.ocrFailed(error)):
//                    state.isProcessingOCR = false
//                    state.ocrError = error
//                    return .none
//                    
//                case .destination:
//                    return .none
//                }
//            }
//        }
//        .ifLet(\.$destination, action: \.destination)
//    }
//}
//
//import ComposableArchitecture
//import Foundation
//
///// Implementation of `ImageAnalysisFeature` action
//extension ImageAnalysisFeature {
//    
//    @CasePathable
//    enum Action: ViewAction, BindableAction {
//        
//        // MARK: - Binding Action
//        
//        /// Handles changes in bindings for the state.
//        case binding(BindingAction<State>)
//        
//        // MARK: - View actions
//        
//        /// Used for view actions.
//        case view(View)
//        
//        enum View {
//            
//            /// The action responsible for completing tasks as soon as the view is displayed.
//            case viewDidAppear
//            
//            case performOCR
//            
//            case ocrCompleted(String)
//            
//            case ocrFailed(String)
//            
//        }
//        
//        // MARK: - Destination
//        
//        /// Destination case for navigation
//        case destination(PresentationAction<Destination.Action>)
//    }
//    
//}
//
//import ComposableArchitecture
//import SwiftUI
//
///// Implementation of `ImageAnalysisFeature` state
//extension ImageAnalysisFeature {
//    
//    @ObservableState
//    struct State {
//        
//        var selectedImage: UIImage
//        
//        var recognizedText: String = ""
//        
//        var isProcessingOCR: Bool = false
//        
//        var ocrError: String?
//        
//        // MARK: - Destination
//        
//        /// Represents the navigation destination state within `ImageAnalysisFeature`.
//        @Presents var destination: Destination.State?
//    }
//}
//
//import ComposableArchitecture
//import Foundation
//
///// Implementation of `ImageAnalysisFeature` destination
//extension ImageAnalysisFeature {
//    
//    @Reducer
//    enum Destination {
//        
//        /// Represents the destination for displaying in `ImageAnalysisFeature`.
//        //        case open(ScoresFeature)
//    }
//    
//}
//
//// MARK: - OCR Function
//private func performOCR(on image: UIImage) async throws -> String {
//    guard let cgImage = image.cgImage else {
//        throw OCRError.invalidImage
//    }
//    
//    return try await withCheckedThrowingContinuation { continuation in
//        let request = VNRecognizeTextRequest { request, error in
//            if let error = error {
//                continuation.resume(throwing: error)
//                return
//            }
//            
//            guard let observations = request.results as? [VNRecognizedTextObservation] else {
//                continuation.resume(returning: "")
//                return
//            }
//            
//            let recognizedStrings = observations.compactMap { observation in
//                observation.topCandidates(1).first?.string
//            }
//            
//            continuation.resume(returning: recognizedStrings.joined(separator: "\n"))
//        }
//        
//        // Konfiguracja dla lepszej dokładności
//        request.recognitionLevel = .accurate
//        request.usesLanguageCorrection = true
//        
//        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
//        
//        DispatchQueue.global(qos: .userInitiated).async {
//            do {
//                try handler.perform([request])
//            } catch {
//                continuation.resume(throwing: error)
//            }
//        }
//    }
//}
//
//enum OCRError: Error {
//    case invalidImage
//}
//
//
//
////import ComposableArchitecture
////import Foundation
////
////@Reducer
////struct ImageAnalysisFeature {
////
////    // MARK: - Reducer
////
////    var body: some Reducer<State, Action> {
////        CombineReducers {
////            BindingReducer()
////            Reduce { state, action in
////                switch action {
////
////                    // MARK: - Binding
////
////                case .binding(_):
////                    return .none
////
////                    // MARK: - View Actions
////
////                case .view(.viewDidAppear):
////                    return .none
////
////                    // MARK: - Destination
////
////                case .destination:
////                    return .none
////                }
////            }
////        }
////        .ifLet(\.$destination, action: \.destination)
////    }
////
////}
