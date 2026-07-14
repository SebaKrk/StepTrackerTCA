//
//  WorkoutFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 10/05/2025.
//

import ComposableArchitecture
import Foundation
import SwiftUI
import PhotosUI

@Reducer
struct WorkoutFeature {
    
    // MARK: - Properties
    
    // MARK: - Lifecycle
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        CombineReducers {
            BindingReducer()
            Reduce { state, action in
                switch action {
                    
                    // MARK: - Binding
                    
                case .binding(_):
                    return .none
                    
                    // MARK: - Actions
                    
                case let .changePhotoSourceOption(item):
                    state.photoSelection = item
                    return .none
                    
                case let .changeWorkoutType(item):
                    state.workoutSelection = item
                    return .none
                    
                    // MARK: - View Actions
                    
                case .view(.viewDidAppear):
                    return .none
                    
                case let .view(.showPhotoPicker(flag)):
                    state.isPickerPresented = flag
                    return .none
                    
                case let .view(.selectedPhotoChanged(photo)):
                    
                    guard let photo else { return .none }
                    
                    return .run { send in
                        if let data = try? await photo.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            await send(.imageLoadedFromLibrary(uiImage))
                        } else {
                            await send(.imageLoadedFromLibrary(nil))
                        }
                    }
                    
                case let .imageLoadedFromLibrary(image):
                    //state.selectedImage = image
                    guard let image else { return .none }
                    state.destination = .openImageAnalysis(ImageAnalysisFeature.State(selectedImage: image))
                    return .none
                    
                case .view(.openCameraView):
                    state.showCamera = true
                    return .none
                    
                case let .view(.imageDataReceived(data)):
                    state.showCamera = false
                    
                    guard let imageData = data else {
                        return .none
                    }
                    
                    state.imageData = imageData
                    
                    if let uiImage = UIImage(data: imageData) {
                        state.destination = .openImageAnalysis(
                            ImageAnalysisFeature.State(selectedImage: uiImage)
                        )
                    }
                    return .none
                
                case .view(.showWorkoutPlaner):
                    state.destination = .openWorkoutPlaner(WorkoutPlanerFeature.State())
                    return .none
                    
                case .view(.showCostumeWorkoutCreator):
                    state.destination = .openCostumeWorkoutCreator(WorkoutCreatorFeature.State())
                    return .none
                    
                case .view(.showWorkoutMirroring):
                    state.destination = .openWorkoutMirroring(WorkoutMirroringFeature.State())
                    return .none
                    
                    // MARK: - Destination
                    
                case .destination:
                    return .none
         
                }
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
    
}

