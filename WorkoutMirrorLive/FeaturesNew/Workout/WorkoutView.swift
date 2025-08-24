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
            VStack {
                Spacer()
                crossFitWorkoutButton
                Spacer()
            }
            .navigationBarTitle("Chose a workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarButtons
            }
        }
    }
    
    @ToolbarContentBuilder
    var toolbarButtons: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                send(.closeButtonTapped)
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.borderedProminent)
            .tint(.pink)
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                
            } label: {
                gearShapeImage
            }
            .badge(1)
            ///.badge("new")
        }
    }
    
    private var gearShapeImage: some View {
        Image(systemName: "gearshape")
    }
    
    private var crossFitWorkoutButton: some View {
        Button {
            
        } label: {
            Image(systemName: "figure")
                .tint(.white)
        }
        .frame(width: 55, height: 55)
        .glassEffect(.regular.interactive(true), in: .capsule)
    }
    
}

//        .buttonStyle(.glassProminent)
//        .tint(.pink)
//        .background(
//            Circle()
//                .fill(.blasck)
//        )

//Button("Toggle Actions") {
//    withAnimation(.bouncy(duration: 1, extraBounce: 0.07)) {
//        progress = progress == 0 ? 1 : 0
//    }
//}
//.buttonStyle(.glassProminent)
//.frame(maxWidth: .infinity)

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
