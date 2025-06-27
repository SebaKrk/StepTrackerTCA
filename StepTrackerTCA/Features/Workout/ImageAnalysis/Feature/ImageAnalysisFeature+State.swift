//
//  State.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 27/06/2025.
//

import ComposableArchitecture
import SwiftUI

/// Implementation of `ImageAnalysisFeature` state
extension ImageAnalysisFeature {
   
   @ObservableState
   struct State {
       
       var selectedImage: UIImage
       
       var recognizedText: String = ""
       
       var isProcessingOCR: Bool = false
       
       var ocrError: String?
       
       // MARK: - Destination
       
       /// Represents the navigation destination state within `ImageAnalysisFeature`.
       @Presents var destination: Destination.State?
   }
    
}
