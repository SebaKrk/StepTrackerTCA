//
//  ImageAnalysisFeature+Action.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 27/06/2025.
//

import ComposableArchitecture
import Foundation

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
           
           case performOCR
           
           case ocrCompleted(String)
           
           case ocrFailed(String)
           
           case openWorkoutGenerator
           
       }
       
       // MARK: - Destination
       
       /// Destination case for navigation
       case destination(PresentationAction<Destination.Action>)
   }
   
}
