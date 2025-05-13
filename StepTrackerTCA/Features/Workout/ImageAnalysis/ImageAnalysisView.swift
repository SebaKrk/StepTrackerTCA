//
//  ImageAnalysisView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 13/05/2025.
//

import ComposableArchitecture
import SwiftUI
import PhotosUI

@ViewAction(for: ImageAnalysisFeature.self)
struct ImageAnalysisView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<ImageAnalysisFeature>
    
    // MARK: - View
    
    var body: some View {
        VStack {
            image
            Spacer()
            actionButton
        }
        
    }
    
    // MARK: - SubView
    
    private var image: some View {
        Image(uiImage: store.selectedImage )
            .resizable()
            .scaledToFit()
            .frame(height: 200)
            .padding()
    }
    
    private var actionButton: some View {
        LabeledButton(title: "Convert to Workout", systemImage: "brain") {
            print("Send workout to Chat and convert to Workout")
        }
    }
}
