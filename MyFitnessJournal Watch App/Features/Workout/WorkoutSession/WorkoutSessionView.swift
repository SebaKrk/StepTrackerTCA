//
//  WorkoutSessionView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 19/05/2025.
//

import ComposableArchitecture
import SwiftUI
import WatchKit

@ViewAction(for: WorkoutSessionFeature.self)
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
        .onAppear {
            send(.viewDidAppear)
        }
        .onChange(of: store.workoutSessionIsRunning, { oldValue, newValue in
            send(.changeTab)
        })
    }
    
    // MARK: - SubViews
    
    @ViewBuilder
    func tabContent(for screen: WorkoutSessionScreenAW) -> some View {
        switch screen {
        case .controls:
            controlsView
        case .workout:
            workoutMetricView
        case .nowPlaying:
            nowPlayingView
        }
    }
    
    private var controlsView: some View {
        ControlsView(store: store.scope(state: \.controlsFeature,
                                     action: \.controlsFeature))
    }
    
    private var nowPlayingView: some View {
        NowPlayingView().tag(WorkoutSessionScreenAW.nowPlaying)
    }
    
    private var workoutMetricView: some View {
        WorkoutMetricView(store: store.scope(state: \.workoutMetricFeature,
                                             action: \.workoutMetricFeature))
    }
}
