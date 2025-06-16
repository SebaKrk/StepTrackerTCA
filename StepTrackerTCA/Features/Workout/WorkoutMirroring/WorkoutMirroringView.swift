//
//  WorkoutMirroringView.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 12/06/2025.
//

import ComposableArchitecture
import SwiftUI
import HealthHub

@ViewAction(for: WorkoutMirroringFeature.self)
struct WorkoutMirroringView: View {
    
    
    @Dependency(\.authorizationManager) var authorizationManager
    @Dependency(\.trainingManager) var trainingManager
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<WorkoutMirroringFeature>
    
    // MARK: - View
    
    var body: some View {
        VStack {
            Text("Waiting for Watch workout...")
            
            Text(store.workoutMetrics.heartRate.formatted(.number.precision(.fractionLength(0))))
                .font(.system(.title, design: .rounded).monospacedDigit().lowercaseSmallCaps())
        }
        .task {
            let result = await authorizationManager.requestAuthorization()
            print("📱 iOS: HealthKit authorization result: \(result)")
            
            trainingManager.setupRemoteSessionHandler()
            print("📱 iOS: Remote session handler setup")
            
            send(.viewDidAppear)
        }
        .onDisappear {
            send(.viewWillDisappear)
        }
    }
}

//        .task {
//            await setupHealthKit()

// Listen to heart rate
//            for await metrics in trainingManager.workoutMetricsStream {
//                heartRate = metrics.heartRate
//                print("📱 iOS: Got HR: \(heartRate)")
//            }
//        }

//    private func setupHealthKit() async {
//        let result = await authorizationManager.requestAuthorization()
//        print("📱 iOS: HealthKit authorization result: \(result)")
//
//        trainingManager.setupRemoteSessionHandler()
//        print("📱 iOS: Remote session handler setup")
//    }

