//
//  WorkoutView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 10/05/2025.
//

import ComposableArchitecture
import SwiftUI
import PhotosUI

@ViewAction(for: WorkoutFeature.self)
struct WorkoutView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<WorkoutFeature>
    
    @State private var photoSelection: PhotoSourceOption = .photo
    @State private var workoutSelection: WorkoutTypeOption = .customWorkout
    
    // MARK: - View
    
    var body: some View {
        NavigationStack {
            Group {
                VStack {
                    photoSourceOptionButton
                    workoutTypeOptionButton
                    historyOptionButton
                }
            }
            .navigationTitle("Workout")
            .navigationBarTitleDisplayMode(.inline)
            .photosPicker(isPresented: $store.isPickerPresented,
                          selection: $store.selectedItem)
            .onChange(of: store.selectedItem) { _, newItem in
                send(.selectedPhotoChanged(newItem))
            }
            .navigationDestination(
                item: $store.scope(
                    state: \.destination?.openImageAnalysis,
                    action: \.destination.openImageAnalysis)) { store in
                        ImageAnalysisView(store: store)
                    }
        }
        
    }
    
    // MARK: - SubView
    
    private var photoSourceOptionButton: some View {
        PickerButtonView(selectedOption: $store.photoSelection.sending(\.changePhotoSourceOption)) { option in
            switch option {
            case .library:
                send(.showPhotoPicker(!store.isPickerPresented))
            case .photo:
                print("chose photo")
            }
        }
        .padding()
    }
    
    private var workoutTypeOptionButton: some View {
        PickerButtonView(selectedOption: $workoutSelection) { option in
            switch option {
            case .customWorkout:
                print("chose custom workout")
            case .singleGoalWorkout:
                print("chose single workout")
            case .pacerWorkout:
                print("chose pacer workout")
            }
        }
        .padding()
    }
    
    private var historyOptionButton: some View {
        LabeledButton(title: "History", systemImage: "calendar") {
            print("onHistoryTapped")
        }
    }
    
}
