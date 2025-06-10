//
//  TrainingSessionTabView.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 28/05/2025.
//

import ComposableArchitecture
import SwiftUI
import WatchKit
import SharedModels

@ViewAction(for: TrainingSessionTabFeature.self)
struct TrainingSessionTabView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<TrainingSessionTabFeature>
    
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
        .onChange(of: store.workoutSessionIsRunning) { oldValue, newValue in
            _ = withAnimation {
                send(.changeTab)
            }
        }
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
        TrainingControlsView(store: store.scope(state: \.controls,
                                     action: \.controls))
    }
   
    private var workoutMetricView: some View {
        TrainingMetricView(store: store.scope(state: \.metric,
                                             action: \.metric))
    }
    
    
    private var nowPlayingView: some View {
        NowPlayingView().tag(WorkoutSessionScreenAW.nowPlaying)
    }
    
}

#Preview {
    TrainingSessionTabView(store: Store(initialState: TrainingSessionTabFeature.State(selectedWorkout: .crossTraining), reducer: {
        TrainingSessionTabFeature()
    }))
}
