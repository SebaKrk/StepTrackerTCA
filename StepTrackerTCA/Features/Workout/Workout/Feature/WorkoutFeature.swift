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
                    
                    // MARK: - Destination
                    
                case .destination:
                    return .none
                }
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
    
}

