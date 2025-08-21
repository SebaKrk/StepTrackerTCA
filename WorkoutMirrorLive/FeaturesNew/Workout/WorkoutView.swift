//
//  WorkoutView.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 20/08/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: WorkoutFeature.self)
struct WorkoutView: View {
    
    // MARK: - Properties
    @Bindable var store: StoreOf<WorkoutFeature>
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                Text("WorkoutFeature")
            }
            .navigationBarTitle("Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarButton
            }
        }
    }
    
    @ToolbarContentBuilder
    var toolbarButton: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                send(.closeButtonTapped)
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.borderedProminent)
            .tint(.pink)
        }
    }
}

//    
//    @ToolbarContentBuilder
//    private var cameraOptionToolBar: some ToolbarContent {
//        ToolbarItemGroup(placement: .bottomBar) {
//            if store.isActiveCamera {
//                activeCameraButton
//                Spacer()
//                recordCameraButton
//            } else {
//                disableCameraButton
//                Spacer()
//            }
//        }
//    }
