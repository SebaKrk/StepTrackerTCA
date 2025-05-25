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
    
    @Bindable var store: StoreOf<HeartRateFeature>

    var body: some View {
        ScrollView {
            VStack {
                Spacer()
                heartRate
                Spacer()
                Button("Start Workout") {
                    send(.startWorkout)
                }
                .buttonStyle(.borderedProminent)
                
                Button("Stop Workout") {
                    send(.stopWorkout)
                }
                .buttonStyle(.borderedProminent)
            }
        }
//        .onAppear {
//            send(.startWorkout)
//        }
    }
    
    private var heartRate: some View {
        HStack {
            heartImage
            Text(store.heartRate.formatted(MetricFormatter.heartRate))
                .font(.system(.title, design: .rounded).monospacedDigit().lowercaseSmallCaps())
            VStack {
                Spacer().frame(height: 10)
                Text("BMP")
                    .font(.footnote)
                    .baselineOffset(-2)
            }
            
        }
    }
    
    private var heartImage: some View {
        Image(systemName: "heart.fill")
            .foregroundStyle(.red)
            .scaleEffect(store.animateHeart ? 1.4 : 1.0)
            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: store.animateHeart)
            .onAppear {
                send(.startHeartAnimation)
            }
    }
}
