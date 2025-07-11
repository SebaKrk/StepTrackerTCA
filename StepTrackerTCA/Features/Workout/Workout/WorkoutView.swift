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
    
    @State private var camera = Camera()
    
    // MARK: - View
    
    var body: some View {
        NavigationStack {
            Group {
                VStack {
                    photoSourceOptionButton
                    workoutTypeOptionButton
                    historyOptionButton
                    workoutMirroringButton
                }
            }
            .navigationTitle("Workout")
            .navigationBarTitleDisplayMode(.inline)
            .photosPicker(isPresented: $store.isPickerPresented,
                          selection: $store.selectedItem)
            .onChange(of: store.selectedItem) { _, newItem in
                send(.selectedPhotoChanged(newItem))
            }
            .sheet(isPresented: $store.showCamera) {
                CameraView(camera: camera, imageData: $store.imageData)
                    .task {
                        await camera.start()
                    }
                    .onChange(of: store.imageData) { _, newData in
                        if let data = newData {
                            send(.imageDataReceived(data))
                        }
                    }
            }
            .sheet(item: $store.scope(state: \.destination?.openWorkoutPlaner,
                                      action: \.destination.openWorkoutPlaner),
                   content: { store in
                WorkoutPlanerView(store: store)
                    .presentationDetents([.medium, .large])
            })
            .sheet(item: $store.scope(state: \.destination?.openCostumeWorkoutCreator,
                                      action: \.destination.openCostumeWorkoutCreator),
                   content: { store in
                WorkoutCreatorView(store: store)
                    .presentationDetents([.large,.medium])
            })
            .navigationDestination(
                item: $store.scope(
                    state: \.destination?.openImageAnalysis,
                    action: \.destination.openImageAnalysis)) { store in
                        ImageAnalysisView(store: store)
                    }
                    .navigationDestination(
                        item: $store.scope(
                            state: \.destination?.openWorkoutMirroring,
                            action: \.destination.openWorkoutMirroring)) { store in
                                WorkoutMirroringView(store: store)
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
                send(.openCameraView)
            }
        }
        .padding()
    }
    
    private var workoutTypeOptionButton: some View {
        PickerButtonView(selectedOption: $store.workoutSelection.sending(\.changeWorkoutType)) { option in
            switch option {
            case .customWorkout:
                print("chose custom workout")
                send(.showCostumeWorkoutCreator)
            case .singleGoalWorkout:
                send(.showWorkoutPlaner)
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
    
    private var workoutMirroringButton: some View {
        LabeledButton(title: "Mirroring", systemImage: "applewatch.case.sizes") {
            send(.showWorkoutMirroring)
        }
    }
    
}
