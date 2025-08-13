//
//  WorkoutSummaryView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 13/08/2025.
//

import ComposableArchitecture
import SwiftUI
import SharedModels

@ViewAction(for: WorkoutSummaryFeature.self)
struct WorkoutSummaryView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<WorkoutSummaryFeature>
    
    // MARK: - View
    
    var body: some View {
        Group {
            switch store.viewState {
            case .loading:
                loadingView
            case .successfullyLoaded:
                Text("successfullyLoaded")
            case .failed:
                Text("failed")
            }
        }
        .onAppear {
            send(.viewDidAppear)
        }
    }
    
    // MARK: - SubView
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView("Saving workout")
                .navigationBarHidden(true)
            Spacer()
        }
        .transition(.opacity)
    }
    
}
