//
//  HeartRateView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 24/05/2025.
//
//

import SwiftUI
import ComposableArchitecture

@ViewAction(for: HeartRateFeature.self)
struct HeartRateView: View {
    let store: StoreOf<HeartRateFeature>

    var body: some View {
        VStack {
            Text("Heart Rate")
                .font(.title)
            Text("\(store.heartRate) bpm")
                .font(.largeTitle)
                .padding()

            Button("Start Workout") {
                send(.startWorkout)
            }
            .buttonStyle(.borderedProminent)
            
            Button("Stop Workout") {
                send(.stopWorkout)
            }
            .buttonStyle(.borderedProminent)
        }
//        .onAppear {
//            send(.startWorkout)
//        }
    }
}
