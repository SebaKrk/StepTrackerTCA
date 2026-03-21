//
//  WorkoutMirrorLiveApp.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 29/07/2025.
//

import AppDatabase
import ComposableArchitecture
import SwiftUI

@main
struct WorkoutMirrorLiveApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        prepareDependencies {
            do {
                try $0.bootstrapDatabase()
            } catch {
                fatalError("Database failed to initialize: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            AppTabNewView(
                store: Store(initialState: AppTabNewFeature.State()) {
                    AppTabNewFeature()
                        ///._printChanges()
                } withDependencies: {
#if targetEnvironment(simulator)
                    $0.trainingReadinessClient = .mock
#endif
                }
            )
        }
    }
    
}

//            HealthMetricCardsView()

//@main
//struct WorkoutMirrorLiveApp: App {
//    var body: some Scene {
//        WindowGroup {
//            AppTabView(
//                store: Store(initialState: AppTabFeature.State()) {
//                    AppTabFeature()
//                }
//            )
//        }
//    }
//}

//@main
//struct WorkoutMirrorLiveApp: App {
//
//    var body: some Scene {
//        WindowGroup {
//            AppTabViewTest()
//        }
//    }
//}
