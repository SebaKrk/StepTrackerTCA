//
//  ImageAnalysisFeature+State.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 27/06/2025.
//

import ComposableArchitecture
import SwiftUI
import Vision

/// Implementation of `ImageAnalysisFeature` state
extension ImageAnalysisFeature {
   
   @ObservableState
   struct State {
       
       /// Selected image for OCR analysis
       var selectedImage: UIImage
       
       /// Text observations with bounding boxes from OCR
       var textObservations: [RecognizedTextObservation] = []
       
       /// Editable text strings corresponding to observations
       var editableTexts: [String] = []
       
       /// Recognized text as string (for WorkoutGenerator compatibility)
       var recognizedText: String = ""
       
       /// Indicates if OCR processing is in progress
       var isProcessingOCR: Bool = false
       
       /// OCR error message if processing fails
       var ocrError: String?
       
       /// Track which text field is being edited
       var editingIndex: Int? = nil
       
       /// Controls image preview sheet
       var showImagePreview: Bool = false
       
       // MARK: - Destination
       
       /// Represents the navigation destination state within `ImageAnalysisFeature`.
       @Presents var destination: Destination.State?
   }
    
}
