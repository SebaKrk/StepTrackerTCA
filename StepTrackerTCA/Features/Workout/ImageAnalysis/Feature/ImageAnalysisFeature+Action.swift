//
//  ImageAnalysisFeature+Action.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 27/06/2025.
//

import ComposableArchitecture
import Foundation
import Vision

/// Implementation of `ImageAnalysisFeature` action
extension ImageAnalysisFeature {
   
   @CasePathable
   enum Action: ViewAction, BindableAction {
       
       // MARK: - Binding Action
       
       /// Handles changes in bindings for the state.
       case binding(BindingAction<State>)
       
       // MARK: - View actions
       
       /// Used for view actions.
       case view(View)
       
       enum View {
           
           /// The action responsible for completing tasks as soon as the view is displayed.
           case viewDidAppear
           
           /// Triggers OCR analysis of the selected image
           case performOCR
           
           /// OCR completed successfully with text observations
           case ocrCompleted([RecognizedTextObservation])
           
           /// OCR failed with error message
           case ocrFailed(String)
           
           /// Updates text at specific index
           case updateText(index: Int, newText: String)
           
           /// Starts editing text at specific index
           case startEditing(index: Int)
           
           /// Stops editing
           case stopEditing
           
           /// Removes text fragment at specific index
           case removeText(index: Int)
           
           /// Shows image preview with bounding boxes
           case showImagePreview
           
           /// Hides image preview
           case hideImagePreview
           
           /// Opens workout generator with recognized text
           case openWorkoutGenerator
           
       }
       
       // MARK: - Destination
       
       /// Destination case for navigation
       case destination(PresentationAction<Destination.Action>)
   }
   
}
