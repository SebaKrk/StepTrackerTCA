//
//  WorkoutSessionView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 19/05/2025.
//

import ComposableArchitecture
import SwiftUI
import WatchKit

struct WorkoutSessionView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<WorkoutSessionFeature>
    
    // MARK: - View
    
    var body: some View {
        TabView(selection: $store.selectedTab.sending(\.tabChanged)) {
            ForEach(WorkoutSessionScreenAW.allCases) { screen in
                tabContent(for: screen)
                    .tag(screen as WorkoutSessionScreenAW?)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(store.selectedTab == .nowPlaying)
    }
    
    @ViewBuilder
    func tabContent(for screen: WorkoutSessionScreenAW) -> some View {
        switch screen {
        case .controls:
            controlsView
        case .workout:
            Text("workout")
        case .nowPlaying:
            nowPlayingView
        }
    }
    
    private var controlsView: some View {
        ControlsView(
            store: Store(initialState: ControlsFeature.State()) {
                ControlsFeature()
            }
        )
    }
    
    private var nowPlayingView: some View {
        NowPlayingView().tag(WorkoutSessionScreenAW.nowPlaying)
    }
    
}
