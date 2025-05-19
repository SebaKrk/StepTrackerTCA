//
//  ControlsView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 19/05/2025.
//
import ComposableArchitecture
import SwiftUI

@ViewAction(for: ControlsFeature.self)
struct ControlsView: View {

    // MARK: - Properties
    
    @Bindable var store: StoreOf<ControlsFeature>
    
    // MARK: - View
    
    var body: some View {
        HStack {
            endButton
            playPauseButton
        }
    }
    
    private var endButton: some View {
        VStack {
            Button {
                send(.endButtonPressed)
            } label: {
                Image(systemName: "xmark")
            }
            .tint(.red)
            .font(.title2)
            Text("End")
        }
    }
    
    private var playPauseButton: some View {
        VStack {
            Button {
                send(.playPauseButtonPressed)
            } label: {
                Image(systemName: "pause")
                ///Image(systemName: workoutManager.running ? "pause" : "play")
            }
            .tint(.yellow)
            .font(.title2)
            Text("Pause")
            ///Text(workoutManager.running ? "Pause" : "Resume")
        }
    }
    
}
