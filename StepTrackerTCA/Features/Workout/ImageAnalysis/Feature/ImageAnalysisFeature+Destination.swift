//
//  ImageAnalysisFeature+Destination.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 27/06/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `ImageAnalysisFeature` destination
extension ImageAnalysisFeature {
   
   @Reducer
   enum Destination {
       
       /// Represents the destination for displaying in `WorkoutGeneratorFeature`.
       case open(WorkoutGeneratorFeature)
   }
   
}
