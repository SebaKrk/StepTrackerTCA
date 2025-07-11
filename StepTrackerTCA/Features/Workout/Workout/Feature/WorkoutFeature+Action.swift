//
//  WorkoutFeature+Action.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 13/05/2025.
//

import ComposableArchitecture
import SwiftUI
import PhotosUI

/// Implementation of `WorkoutFeature` action
extension WorkoutFeature {
    
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - Actions
        
        ///
        case changePhotoSourceOption(PhotoSourceOption)
        
        ///
        case changeWorkoutType(WorkoutTypeOption)
        
        ///
        case imageLoadedFromLibrary(UIImage?)
        
        // MARK: - View actions
        
        /// Used for view actions.
        case view(View)
        
        enum View {
            
            /// The action responsible for completing tasks as soon as the view is displayed.
            case viewDidAppear
            
            ///
            case showPhotoPicker(Bool)
            
            ///
            case openCameraView
            
            ///
            case imageDataReceived(Data?)
            
            ///
            case selectedPhotoChanged(PhotosPickerItem?)
            
            ///
            case showWorkoutPlaner
            
            ///
            case showWorkoutMirroring
            
            ///
            case showCostumeWorkoutCreator
            
        }
        
        // MARK: - Destination
        
        /// Destination case for navigation
        case destination(PresentationAction<Destination.Action>)
    }
}
