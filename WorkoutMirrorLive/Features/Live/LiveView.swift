//
//  LiveView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 31/07/2025.
//

import ComposableArchitecture
import SwiftUI

@ViewAction(for: LiveFeature.self)
struct LiveView: View {
    
    // MARK: - Properties
    @Bindable var store: StoreOf<LiveFeature>
    
    // MARK: - Body
    
    var body: some View {
        rootView
            .fullScreenCover(item: $store.scope(state: \.destination?.openWorkoutMirroringView,
                                                action: \.destination.openWorkoutMirroringView)) { store in
                WorkoutMirroringView(store: store)
            }
    }
    
    // MARK: - SubView
    
    var rootView: some View {
        timerButton
    }
    
    private var timerButton: some View {
        Button {
            send(.startWorkoutMirror)
        } label: {
            Image(systemName: "stopwatch")
                .padding()
                .glassEffect()
                .foregroundStyle(.white)
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [.white, .gray]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

//            .sheet(item: $store.scope(state: \.destination?.openWorkoutMirroringView,
//                                      action: \.destination.openWorkoutMirroringView)) { store in
//                WorkoutMirroringView(store: store)
//
//                    .presentationDetents([.large])
//            }
