//
//  TrainingControlsView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 28/05/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: TrainingControlsFeature.self)
struct TrainingControlsView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<TrainingControlsFeature>
    
    // MARK: - View
    
    var body: some View {
        HStack {
            endButton
            playPauseButton
        }
        
    }
    
    // MARK: - SubView
    
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
                send(.togglePauseButtonPressed)
            } label: {
                Image(systemName: store.sessionIsRunning ? "pause" : "play")
            }
            .tint(.yellow)
            .font(.title2)
            Text(store.sessionIsRunning ? "Pause" : "Resume")
        }
    }

}

