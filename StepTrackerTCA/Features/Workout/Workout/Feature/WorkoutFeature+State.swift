//
//  WorkoutFeature+State.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 13/05/2025.
//

import ComposableArchitecture
import SwiftUI
import PhotosUI

/// Implementation of `WorkoutFeature` state
extension WorkoutFeature {
    
    @ObservableState
    struct State {
        
        var photoSelection: PhotoSourceOption = .photo
        
        var isPickerPresented: Bool = false
        
        var selectedItem: PhotosPickerItem? = nil
        
        //var selectedImage: UIImage? = nil
        
        // MARK: - Destination
        
        /// Represents the navigation destination state within `SummaryFeature`.
        @Presents var destination: Destination.State?
    }
    
}
